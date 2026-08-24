import { hilog } from '@kit.PerformanceAnalysisKit';

export class AppLogger {
  private static readonly DOMAIN: number = 0x0001;

  static error(module: string, action: string, error: Error): void {
    const errorType: string = error.name.length > 0 ? error.name : 'UnknownError';
    hilog.error(
      AppLogger.DOMAIN,
      module,
      '%{public}s failed (%{public}s)',
      action,
      errorType
    );
  }
}
