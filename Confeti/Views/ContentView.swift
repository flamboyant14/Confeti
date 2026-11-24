import SwiftUI

enum ModoJuego: String, CaseIterable, Identifiable, Hashable {
    case adivina
    case primeraLetra
    case escribe
    case cuenta
    case sumasNiveles
    case restasNiveles
    case multiplicacionesNiveles
    case divisionesNiveles

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .adivina: return "¿Dónde está?"
        case .primeraLetra: return "¿Con qué empieza?"
        case .escribe: return "Escribe"
        case .cuenta: return "Cuenta y traza"
        case .sumasNiveles: return "Sumas Mágicas"
        case .restasNiveles: return "Restas Mágicas"
        case .multiplicacionesNiveles: return "Multiplica"
        case .divisionesNiveles: return "Divisiones Mágicas"
        }
    }

    var subtitulo: String {
        switch self {
        case .adivina: return "Toca el dibujo correcto"
        case .primeraLetra: return "Elige la letra inicial"
        case .escribe: return "Traza la palabra"
        case .cuenta: return "Cuenta objetos y números"
        case .sumasNiveles: return "25 niveles de sumas"
        case .restasNiveles: return "25 niveles de restas"
        case .multiplicacionesNiveles: return "25 niveles de tablas"
        case .divisionesNiveles: return "25 niveles de repartir"
        }
    }

    var icono: String {
        switch self {
        case .adivina: return "photo.badge.checkmark"
        case .primeraLetra: return "textformat.abc"
        case .escribe: return "pencil.and.list.clipboard"
        case .cuenta: return "number.circle.fill"
        case .sumasNiveles: return "plus.circle.fill"
        case .restasNiveles: return "minus.circle.fill"
        case .multiplicacionesNiveles: return "multiply.circle.fill"
        case .divisionesNiveles: return "divide.circle.fill"
        }
    }

    var muestraPorDefecto: String {
        switch self {
        case .adivina: return "🍎"
        case .primeraLetra: return "ABC"
        case .escribe: return "✍️"
        case .cuenta: return "123"
        case .sumasNiveles: return "🔢"
        case .restasNiveles: return "➖"
        case .multiplicacionesNiveles: return "✖️"
        case .divisionesNiveles: return "➗"
        }
    }
}

enum Origen: Hashable {
    case aprender
    case juegos
}

enum Pantalla: Hashable {
    case inicio
    case mapa
    case aprender
    case juegos
    case tablero(Categoria)
    case sesion(Categoria, [String])
    case nombre
    case juego(ModoJuego)
    case cierre(ganadas: Int, antes: Int, origen: Origen)
    case album
}

struct ContentView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @State private var ruta: [Pantalla] = []
    @State private var mostrarAjustes = false

    var body: some View {
        NavigationStack(path: $ruta) {
            PerfilesView(
                entrar: { perfil in
                    perfiles.activoID = perfil.id
                    ruta = [.inicio]
                },
                ajustes: { mostrarAjustes = true }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Pantalla.self) { pantalla in
                destino(pantalla)
            }
        }
        .statusBarHidden(true)
        .onAppear { Musica.shared.actualizar() }
        .sheet(isPresented: $mostrarAjustes) {
            AjustesView()
        }
    }

    private func terminar(origen: Origen) -> (Int, Int) -> Void {
        { ganadas, antes in
            ruta.append(.cierre(ganadas: ganadas, antes: antes, origen: origen))
        }
    }

    @ViewBuilder
    private func destino(_ pantalla: Pantalla) -> some View {
        if let perfil = perfiles.activo {
            switch pantalla {
            case .inicio:
                InicioView(perfil: perfil, jugar: { ruta.append(.mapa) }, album: { ruta.append(.album) })
                    .toolbar(.hidden, for: .navigationBar)

            case .mapa:
                MapaView(aprender: { ruta.append(.aprender) }, jugar: { ruta.append(.juegos) })
                    .toolbar(.hidden, for: .navigationBar)

            case .aprender:
                AprenderView(
                    elegir: { categoria in ruta.append(.tablero(categoria)) },
                    nombre: { ruta.append(.nombre) }
                )
                .toolbar(.hidden, for: .navigationBar)

            case .juegos:
                JuegosView(elegir: { modo in ruta.append(.juego(modo)) })
                    .toolbar(.hidden, for: .navigationBar)

            case .tablero(let categoria):
                TableroView(categoria: categoria, empezar: { claves in
                    ruta.append(.sesion(categoria, claves))
                })
                .toolbar(.hidden, for: .navigationBar)

            case .sesion(let categoria, let claves):
                SesionView(categoria: categoria, claves: claves, terminar: terminar(origen: .aprender))
                    .toolbar(.hidden, for: .navigationBar)

            case .nombre:
                NombreSesionView(terminar: terminar(origen: .aprender))
                    .toolbar(.hidden, for: .navigationBar)

            case .juego(let modo):
                destinoJuego(modo)
                    .toolbar(.hidden, for: .navigationBar)

            case .cierre(let ganadas, let antes, let origen):
                CierreView(
                    ganadas: ganadas,
                    antes: antes,
                    inicio: { ruta = [.inicio] },
                    album: { ruta.append(.album) },
                    seguir: { ruta = [.inicio, .mapa, origen == .aprender ? .aprender : .juegos] }
                )
                .toolbar(.hidden, for: .navigationBar)

            case .album:
                AlbumView()
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    @ViewBuilder
    private func destinoJuego(_ modo: ModoJuego) -> some View {
        switch modo {
        case .adivina:
            AdivinaView(terminar: terminar(origen: .juegos))
        case .primeraLetra:
            PrimeraLetraView(terminar: terminar(origen: .juegos))
        case .escribe:
            EscribePalabraView(terminar: terminar(origen: .juegos))
        case .cuenta:
            CuentaView(terminar: terminar(origen: .juegos))
        case .sumasNiveles:
            SumaNivelesView(terminarSesion: terminar(origen: .juegos), alSalir: {
                if !ruta.isEmpty { ruta.removeLast() }
            })
            .toolbar(.hidden, for: .navigationBar)
        case .restasNiveles:
            MatematicasNivelesView(tipo: .resta, terminarSesion: terminar(origen: .juegos), alSalir: {
                if !ruta.isEmpty { ruta.removeLast() }
            })
            .toolbar(.hidden, for: .navigationBar)
        case .multiplicacionesNiveles:
            MatematicasNivelesView(tipo: .multiplicacion, terminarSesion: terminar(origen: .juegos), alSalir: {
                if !ruta.isEmpty { ruta.removeLast() }
            })
            .toolbar(.hidden, for: .navigationBar)
        case .divisionesNiveles:
            MatematicasNivelesView(tipo: .division, terminarSesion: terminar(origen: .juegos), alSalir: {
                if !ruta.isEmpty { ruta.removeLast() }
            })
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView()
        .environment(PerfilesStore.vistaPrevia())
}
