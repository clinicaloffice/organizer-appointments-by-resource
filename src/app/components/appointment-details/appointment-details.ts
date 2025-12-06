import { DatePipe } from '@angular/common';
import { afterNextRender, ChangeDetectionStrategy, Component, inject, input, signal, WritableSignal } from '@angular/core';
import { ButtonDirective, CustomService, IMenuItem, MpageIconComponent, TabbedMenuComponent, MpageTableComponent } from "@clinicaloffice/mpage-developer";

@Component({
  selector: 'app-appointment-details',
  imports: [ButtonDirective, MpageIconComponent, TabbedMenuComponent, DatePipe, MpageTableComponent],
  templateUrl: './appointment-details.html',
  styleUrl: './appointment-details.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: true
})
export class AppointmentDetails {
  public dialogRef = input<HTMLDialogElement>();
  public data = input<any>();

  protected customService = inject(CustomService);
  protected menuItems: IMenuItem[] = [
    { label: 'Information', idName: 'info' },
    { label: 'Details', idName: 'details' },
    { label: 'Attached Orders', idName: 'orders' }
  ];
  protected tab: WritableSignal<string> = signal('info');
  protected allowRender: WritableSignal<boolean> = signal(false);

  constructor() {
    afterNextRender(() => {
      this.allowRender.set(true);
    })
  }

}
