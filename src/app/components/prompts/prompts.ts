import { ChangeDetectionStrategy, Component, inject, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ButtonDirective, MpageIconComponent, MpageDateRangePickerComponent, MpageSelectComponent, ISelectValue, IDateRange, CustomService } from '@clinicaloffice/mpage-developer';

@Component({
  selector: 'app-prompts',
  imports: [FormsModule, ButtonDirective, MpageIconComponent, MpageDateRangePickerComponent, MpageSelectComponent],
  templateUrl: './prompts.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: true
})
export class Prompts {
  protected customService = inject(CustomService);

  public dataReady = output<boolean>();

  protected rangeTypes: ISelectValue[] = [{ key: 'between', value: 'Between' }];
  protected datePrompt: IDateRange = { range: 'between', fromDate: new Date(), toDate: new Date() };
  protected resourcePrompt: number[] = [];  

  // Refresh the table data
  protected refresh(): void {
    this.customService.load({
      name: '1trn_appt_by_res:group1',
      run: 'pre',
      id: 'tableData',
      parameters: {
        action: 'load-table',
        fromDate: this.customService.MPage.formatDate(this.datePrompt.fromDate, false),
        toDate: this.customService.MPage.formatDate(this.datePrompt.toDate, false),
        resourceCd: this.resourcePrompt
      }
    }, undefined, () => {
      this.dataReady.emit(true);
    });
  }

  // Determine if all required prompts completed
  protected requirementsNotMet(): boolean {
    return this.resourcePrompt.length === 0;
  }
}
