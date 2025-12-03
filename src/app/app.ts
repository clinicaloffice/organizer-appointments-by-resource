import {ChangeDetectionStrategy, Component, inject, OnInit} from '@angular/core';
import {CUSTOM_DATE_FORMATS} from './app.config';
import {
  MPageService,
  MpageLogComponent,
  AddressService,
  AllergyService,
  CodeValueService,
  ConfigService,
  CustomService,
  DiagnosisService,
  EncounterService,
  Dialog,
  OrganizationService, PersonService, PhoneService, ProblemService, ReferenceService, PrsnlService
} from '@clinicaloffice/mpage-developer';

@Component({
  selector: 'app-root',
  imports: [MpageLogComponent],
  templateUrl: './app.html',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [MPageService, AddressService, AllergyService, CodeValueService, ConfigService, CustomService,
    DiagnosisService, EncounterService, Dialog, OrganizationService, PersonService, PhoneService,
    ProblemService, PrsnlService, ReferenceService]
})
export class App implements OnInit {
  public MPage = inject(MPageService);

  ngOnInit() {
    this.MPage.setMaxInstances(2, true, 'CHART', false);
    this.MPage.defaultDateFormats = CUSTOM_DATE_FORMATS;
  }
}
