import { common } from '@kit.AbilityKit';
import { audio } from '@kit.AudioKit';
import { media } from '@kit.MediaKit';
import { vibrator } from '@kit.SensorServiceKit';
import { AppLogger } from '../common/AppLogger';

export type ReadingFeedbackEvent = 'shuffle' | 'selection' | 'reveal';

export interface ReadingFeedbackPort {
  play(event: ReadingFeedbackEvent): void;
  vibrate(event: ReadingFeedbackEvent): void;
}

export class SoundPoolLoadState {
  private trackedSoundId: number = 0;
  private completedSoundId: number = 0;

  track(soundId: number): void {
    this.trackedSoundId = soundId;
  }

  markLoadComplete(soundId: number): void {
    this.completedSoundId = soundId;
  }

  canPlay(): boolean {
    return this.trackedSoundId > 0 && this.trackedSoundId === this.completedSoundId;
  }

  readySoundId(): number {
    return this.canPlay() ? this.trackedSoundId : 0;
  }

  reset(): void {
    this.trackedSoundId = 0;
    this.completedSoundId = 0;
  }
}

export class ReadingFeedbackService {
  private readonly port: ReadingFeedbackPort;

  constructor(port: ReadingFeedbackPort) {
    this.port = port;
  }

  emit(event: ReadingFeedbackEvent, soundEnabled: boolean, hapticEnabled: boolean): void {
    if (soundEnabled) {
      this.port.play(event);
    }
    if (hapticEnabled) {
      this.port.vibrate(event);
    }
  }
}

export class NativeReadingFeedbackPort implements ReadingFeedbackPort {
  private static readonly RAW_FILE: string = 'reading_feedback.wav';
  private static readonly MAX_CONCURRENT_STREAMS: number = 2;
  private static readonly CLICK_PLAY_PARAMETERS: media.PlayParameters = {
    loop: 0,
    leftVolume: 1,
    rightVolume: 1,
    priority: 1
  };
  private soundPool: media.SoundPool | null = null;
  private readonly soundLoadState: SoundPoolLoadState = new SoundPoolLoadState();
  private initialization: Promise<void> | null = null;

  async initialize(context: common.Context): Promise<void> {
    if (this.initialization === null) {
      this.initialization = this.loadSound(context);
    }
    await this.initialization;
  }

  play(_event: ReadingFeedbackEvent): void {
    const soundId: number = this.soundLoadState.readySoundId();
    if (this.soundPool === null || soundId === 0) {
      return;
    }
    this.soundPool.play(soundId, NativeReadingFeedbackPort.CLICK_PLAY_PARAMETERS).catch((error: Error): void => {
      AppLogger.error('NativeReadingFeedbackPort', 'play', error);
    });
  }

  vibrate(event: ReadingFeedbackEvent): void {
    vibrator.startVibration(
      { type: 'time', duration: this.durationFor(event) },
      { usage: 'touch' }
    ).catch((error: Error): void => {
      AppLogger.error('NativeReadingFeedbackPort', 'vibrate', error);
    });
  }

  private async loadSound(context: common.Context): Promise<void> {
    let failedPool: media.SoundPool | null = null;
    try {
      const pool: media.SoundPool = await media.createSoundPool(NativeReadingFeedbackPort.MAX_CONCURRENT_STREAMS, {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 0
      });
      failedPool = pool;
      let loadFinished: boolean = false;
      const loadComplete: Promise<void> = new Promise((resolve: () => void, reject: (error: Error) => void): void => {
        pool.on('loadComplete', (soundId: number): void => {
          this.soundLoadState.markLoadComplete(soundId);
          loadFinished = true;
          resolve();
        });
        pool.on('error', (error: Error): void => {
          if (loadFinished) {
            AppLogger.error('NativeReadingFeedbackPort', 'soundPool', error);
            return;
          }
          reject(error);
        });
      });
      const rawFile = await context.resourceManager.getRawFd(NativeReadingFeedbackPort.RAW_FILE);
      try {
        const soundId: number = await pool.load(rawFile.fd, rawFile.offset, rawFile.length);
        this.soundLoadState.track(soundId);
      } finally {
        await context.resourceManager.closeRawFd(NativeReadingFeedbackPort.RAW_FILE);
      }
      await loadComplete;
      if (!this.soundLoadState.canPlay()) {
        throw new Error('SoundPool completed an unexpected sound load.');
      }
      this.soundPool = pool;
      failedPool = null;
    } catch (error) {
      this.soundLoadState.reset();
      this.initialization = null;
      if (failedPool !== null) {
        failedPool.release().catch((releaseError: Error): void => {
          AppLogger.error('NativeReadingFeedbackPort', 'releaseSoundPool', releaseError);
        });
      }
      AppLogger.error('NativeReadingFeedbackPort', 'loadSound', error);
    }
  }

  private durationFor(event: ReadingFeedbackEvent): number {
    if (event === 'reveal') {
      return 45;
    }
    if (event === 'selection') {
      return 30;
    }
    return 24;
  }
}
