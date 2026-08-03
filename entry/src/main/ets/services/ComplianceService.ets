export class ComplianceService {
  static readonly CURRENT_VERSION: string = '2026-08-03-v1';

  static requiresAcceptance(acceptedVersion: string): boolean {
    return acceptedVersion !== ComplianceService.CURRENT_VERSION;
  }
}
