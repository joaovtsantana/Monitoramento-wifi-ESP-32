import { TestBed } from '@angular/core/testing';

import { Coletas } from './coletas';

describe('Coletas', () => {
  let service: Coletas;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(Coletas);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
