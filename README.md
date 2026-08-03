# Travel Intelligence

MVP instalável para analisar cotações de viagem. Extrai datas, voos, hotel, passageiros e valor; avalia horários, bagagem, taxas e regras; permite comparar o pacote com preços reais informados pelo usuário; e gera perguntas para a agência.

## Executar

```bash
python -m http.server 8080
```

Abra `http://localhost:8080`. Não há dependências ou build.

## Limite atual

O MVP não consulta preços ao vivo e não inventa cotações. A próxima fase requer backend seguro, leitura de PDF/imagem e APIs oficiais de voos e hospedagem. Chaves de API nunca devem ficar no frontend.

Veja [arquitetura](docs/ARCHITECTURE.md) e [roadmap](docs/ROADMAP.md).
