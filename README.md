# **📐 Envoltória Convexa (Convex Hull) em Godot 4.x**

Repositório dedicado à visualização e análise de desempenho do algoritmo de Envoltória Convexa (Monotone Chain) implementado na Godot Engine usando GDScript.

O projeto permite a interação em tempo real com conjuntos de pontos, além de gerar dados de custo computacional (tempo de execução) para análise de complexidade e crescimento.

## **✨ Recursos e Interação**

O projeto é executado como uma cena 2D interativa onde o usuário pode manipular os pontos e acionar a análise.

| Tecla / Evento | Ação |
| :---- | :---- |
| **Clique do Mouse** | Adiciona um novo ponto na posição do clique. |
| **R** | Gera um novo conjunto de **pontos aleatórios** (initial\_num\_points). |
| **C** | Gera pontos em formato de **círculo** (pior caso para o algoritmo). |
| **T** | Gera pontos em formato de **triângulo**. |
| **B** | Gera pontos em formato de **retângulo**. |
| **X** | Limpa todos os pontos da tela. |
| **A** | Executa a **Análise de Complexidade** completa, gerando o arquivo complexity\_analysis.csv. |

## **📊 Análise de Desempenho e Geração de Dados**

O projeto foi configurado para exportar dois tipos principais de relatórios CSV, essenciais para a sua análise:

### **1\. last\_points\_export.csv (Dados Detalhados)**

Gerado sempre que um novo conjunto de pontos é criado ou modificado (cliques, R, C, T, B). Este arquivo contém as coordenadas de cada ponto e os metadados da última execução:

| Coluna | Descrição |
| :---- | :---- |
| x, y | Coordenadas do ponto. |
| is\_hull | 1 se o ponto está na envoltória, 0 caso contrário. |
| elapsed\_ms | **Custo Computacional** (Tempo em milissegundos) para calcular o hull daquele conjunto. |
| n\_points | Número total de pontos no conjunto. |
| n\_hull | Número de pontos na envoltória. |
| density | Densidade de pontos internos (proporção de pontos que não fazem parte do hull). |

### **2\. complexity\_analysis.csv (Dados de Crescimento)**

Gerado ao pressionar a tecla **A** (Análise) ou na inicialização do jogo. Ele mede o crescimento do custo computacional em função do aumento do número de pontos ($N$).

Ele compara dois cenários:

* **time\_ms\_random**: Caso típico (pontos aleatórios).  
* **time\_ms\_circle**: Pior caso (pontos em círculo, onde $N\_{hull}=N$).

| Coluna | Descrição |
| :---- | :---- |
| n\_points | Número de pontos no teste ($N$). |
| time\_ms\_random | Tempo de execução (ms) para pontos aleatórios. |
| n\_hull\_random | Tamanho da envoltória (hull) para pontos aleatórios. |
| time\_ms\_circle | Tempo de execução (ms) para pontos em círculo. |
| n\_hull\_circle | Tamanho da envoltória (hull) para pontos em círculo (deve ser aproximadamente igual a $N$). |

## **📈 Análise Gráfica com Python (Google Colab / Jupyter)**

O arquivo analysis\_script.py (ou notebook Colab) incluído neste projeto permite a visualização automática dos dados gerados, plotando gráficos como:

1. **Curva de Crescimento:** Comparação do tempo de execução com a complexidade teórica $O(N \\log N)$ para validar o algoritmo Monotone Chain.  
2. **Distribuição de Pontos:** Visualização do último conjunto de pontos exportado, destacando o hull.

## **📘 Parte teórica — Relação entre Envoltória Convexa e Diagrama de Voronoi**

A envoltória convexa e o diagrama de Voronoi são estruturas geométricas fundamentais e intimamente relacionadas em Geometria Computacional.

O Diagrama de Voronoi particiona o espaço em regiões — cada ponto do plano é associado ao sítio (ponto) mais próximo.

Já a envoltória convexa é o menor polígono convexo que contém todos os pontos do conjunto.  
A conexão entre ambos surge porque:

* As arestas externas do Diagrama de Voronoi estão diretamente ligadas à envoltória convexa do conjunto de pontos;  
* Os vértices do diagrama de Voronoi correspondem às circuncentrais dos triângulos formados pela Triangulação de Delaunay, que é o dual do Diagrama de Voronoi;  
* E a Triangulação de Delaunay, por sua vez, tem como fronteira justamente a envoltória convexa do conjunto.

Assim, podemos dizer que a envoltória convexa é a fronteira externa da estrutura de Voronoi/Delaunay.

## **⚙️ Como Rodar o Projeto**

1. **Pré-requisito:** Instale a Godot Engine 4.x (o projeto foi desenvolvido na versão 4.5).  
2. **Clone o Repositório:**  
   git clone \[https://github.com/felipehaertel/envoltoria\_convexa.git\](https://github.com/felipehaertel/envoltoria\_convexa.git)  
   cd envoltoria\_convexa

3. **Abra na Godot:** Importe a pasta clonada como um projeto na Godot Engine.  
4. **Execute:** Execute a cena principal (pressione F5).

Os arquivos CSV serão gerados no diretório de usuário do Godot (user://), que normalmente está localizado em um diretório oculto no sistema operacional. Para análise, copie-os para o ambiente Colab ou para o diretório local do script Python.