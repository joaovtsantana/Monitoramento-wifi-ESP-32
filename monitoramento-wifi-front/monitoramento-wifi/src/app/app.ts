import { Component, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ColetasService } from './services/coletas';
import { DatePipe } from '@angular/common';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, DatePipe],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App implements OnInit {

  coletas: any[] = [];
  medicoes: any[] = [];
  coletaSelecionada: any = null;

  constructor(private coletasService: ColetasService) {}

  ngOnInit(): void {
    this.coletasService.listarColetas().subscribe({
      next: (dados) => {
        this.coletas = dados;
        console.log('Coletas carregadas:', this.coletas);
      },
      error: (erro) => {
        console.error('Erro ao carregar coletas:', erro);
      }
    });
  }

  selecionarColeta(event: Event): void {
  const id = Number((event.target as HTMLSelectElement).value);

  if (!id) {
    return;
  }

  this.coletasService.buscarColeta(id).subscribe({
    next: (dados) => {
      this.coletaSelecionada = dados.coleta;
      this.medicoes = dados.medicoes;
    },
    error: (erro) => {
      console.error('Erro ao buscar coleta:', erro);
    }
  });
}
}
