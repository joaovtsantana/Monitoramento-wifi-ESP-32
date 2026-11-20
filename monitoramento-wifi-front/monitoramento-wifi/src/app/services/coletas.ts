import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class ColetasService {

  private apiUrl = 'http://localhost:3001/coletas';

  constructor(private http: HttpClient) {}

  listarColetas() {
    return this.http.get<any[]>(this.apiUrl);
  }

  buscarColeta(id: number) {
    return this.http.get<any>(`${this.apiUrl}/${id}`);
  }
}
