import { describe, expect, it } from '@ohos/hypium';
import { ResponsiveLayout } from '../../../main/ets/common/ResponsiveLayout';

export default function responsiveLayoutTest(): void {
  describe('ResponsiveLayout', () => {
    it('usesCompactCatalogColumnsOnPhones', 0, () => {
      expect(ResponsiveLayout.catalogColumns(359)).assertEqual(2);
      expect(ResponsiveLayout.catalogColumns(599)).assertEqual(3);
    });

    it('addsColumnsWhenTabletWidthIsAvailable', 0, () => {
      expect(ResponsiveLayout.catalogColumns(600)).assertEqual(4);
      expect(ResponsiveLayout.selectionColumns(600)).assertEqual(5);
    });

    it('buildsStableArkUIColumnTemplates', 0, () => {
      expect(ResponsiveLayout.catalogTemplate(600)).assertEqual('1fr 1fr 1fr 1fr');
      expect(ResponsiveLayout.selectionTemplate(599)).assertEqual('1fr 1fr 1fr 1fr');
    });
  });
}
