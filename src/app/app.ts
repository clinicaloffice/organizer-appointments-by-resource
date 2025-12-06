import { ChangeDetectionStrategy, Component, inject, OnInit, signal, WritableSignal } from '@angular/core';
import { CUSTOM_DATE_FORMATS } from './app.config';
import { MPageService, MpageLogComponent, AddressService, AllergyService, CodeValueService, ConfigService, CustomService, DiagnosisService, EncounterService, Dialog, OrganizationService, PersonService, PhoneService, ProblemService, ReferenceService, PrsnlService, MpageTableComponent, RemainingScreenSpaceDirective } from '@clinicaloffice/mpage-developer';
import { Prompts } from "./components/prompts/prompts";
import { AppointmentDetails } from './components/appointment-details/appointment-details';

@Component({
  selector: 'app-root',
  imports: [MpageLogComponent, Prompts, MpageTableComponent, RemainingScreenSpaceDirective],
  templateUrl: './app.html',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [MPageService, AddressService, AllergyService, CodeValueService, ConfigService, CustomService,
    DiagnosisService, EncounterService, Dialog, OrganizationService, PersonService, PhoneService,
    ProblemService, PrsnlService, ReferenceService]
})
export class App implements OnInit {
  public MPage = inject(MPageService);
  protected customService = inject(CustomService);
  private dialog = inject(Dialog);

  protected tableData: WritableSignal<any[]> = signal([]);

  ngOnInit() {
    this.MPage.setMaxInstances(2, true, 'ORGANIZER', false);
    this.MPage.defaultDateFormats = CUSTOM_DATE_FORMATS;
  }

  // Populate the tableData signal with the values from custom service
  protected loadTable() {
    if (this.customService.has('tableData')) {
      this.tableData.set(this.customService.get('tableData').data);
    }
  }

  // Initiate the dialog showing the appointment details
  protected showDetails(tableRow: any) {
    this.customService.clear('eventData');
    this.customService.load({
      name: '1trn_appt_by_res:group1',
      run: 'pre',
      id: 'eventData',
      parameters: {
        action: 'load-event',
        schEventId: tableRow.schEventId
      }
    }, undefined, () => {
      const dialogRef = this.dialog.open(AppointmentDetails, {
        width: '90vw',
        minHeight: '50vh',
        data: tableRow
      });
    });
  }
}
