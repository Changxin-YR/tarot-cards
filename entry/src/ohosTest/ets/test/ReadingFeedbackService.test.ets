import { describe, expect, it } from '@ohos/hypium';
import {
  ReadingFeedbackEvent,
  ReadingFeedbackPort,
  ReadingFeedbackService,
  SoundPoolLoadState
} from '../../../main/ets/services/ReadingFeedbackService';

class FeedbackRecorder implements ReadingFeedbackPort {
  soundCount: number = 0;
  vibrationCount: number = 0;
  latestSound: ReadingFeedbackEvent = 'shuffle';
  latestVibration: ReadingFeedbackEvent = 'shuffle';

  play(event: ReadingFeedbackEvent): void {
    this.soundCount += 1;
    this.latestSound = event;
  }

  vibrate(event: ReadingFeedbackEvent): void {
    this.vibrationCount += 1;
    this.latestVibration = event;
  }
}

export default function readingFeedbackServiceTest(): void {
  describe('ReadingFeedbackService', () => {
    it('dispatchesOnlyTheFeedbackChannelsEnabledBySettings', 0, () => {
      const recorder: FeedbackRecorder = new FeedbackRecorder();
      const feedback: ReadingFeedbackService = new ReadingFeedbackService(recorder);

      feedback.emit('shuffle', false, false);
      expect(recorder.soundCount).assertEqual(0);
      expect(recorder.vibrationCount).assertEqual(0);

      feedback.emit('selection', true, false);
      expect(recorder.soundCount).assertEqual(1);
      expect(recorder.latestSound).assertEqual('selection');
      expect(recorder.vibrationCount).assertEqual(0);

      feedback.emit('reveal', false, true);
      expect(recorder.soundCount).assertEqual(1);
      expect(recorder.vibrationCount).assertEqual(1);
      expect(recorder.latestVibration).assertEqual('reveal');
    });

    it('waitsForTheMatchingLoadCompleteEventBeforePlaying', 0, () => {
      const state: SoundPoolLoadState = new SoundPoolLoadState();

      state.track(7);
      expect(state.canPlay()).assertFalse();

      state.markLoadComplete(6);
      expect(state.canPlay()).assertFalse();

      state.markLoadComplete(7);
      expect(state.canPlay()).assertTrue();
      expect(state.readySoundId()).assertEqual(7);
    });

    it('acceptsLoadCompletionThatArrivesBeforeTheLoadPromiseResolves', 0, () => {
      const state: SoundPoolLoadState = new SoundPoolLoadState();

      state.markLoadComplete(9);
      state.track(9);

      expect(state.canPlay()).assertTrue();
      expect(state.readySoundId()).assertEqual(9);
    });
  });
}
