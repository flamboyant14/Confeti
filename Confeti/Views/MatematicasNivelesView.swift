import SwiftUI

enum TipoOperacion: String, Hashable {
    case resta
    case multiplicacion
    case division
    
    var tituloMenu: String {
        switch self {
        case .resta: return "Restas Mágicas"
        case .multiplicacion: return "Multiplica"
        case .division: return "Divisiones Mágicas"
        }
    }
    
    var emoji: String {
        switch self {
        case .resta: return "➖"
        case .multiplicacion: return "✖️"
        case .division: return "➗"
        }
    }
    
    var colorBase: Color {
        switch self {
        case .resta: return Color.azul
        case .multiplicacion: return Color.turquesa
        case .division: return Color.naranja
        }
    }
}

struct ProblemaMate: Identifiable {
    let id = UUID()
    let a: Int
    let b: Int
    let operacion: TipoOperacion
    
    var simbolo: String {
        switch operacion {
        case .resta: return "-"
        case .multiplicacion: return "×"
        case .division: return "÷"
        }
    }
    
    var respuestaCorrecta: Int {
        switch operacion {
        case .resta: return a - b
        case .multiplicacion: return a * b
        case .division: return b != 0 ? a / b : 0
        }
    }
    
    let opciones: [Int]
}

struct MatematicasNivelesView: View {
    let tipo: TipoOperacion
    let terminarSesion: (Int, Int) -> Void
    let alSalir: () -> Void
    
    @Environment(PerfilesStore.self) private var perfiles
    @AppStorage private var nivelMaximoDesbloqueado: Int
    
    @State private var nivelSeleccionado: Int? = nil
    @State private var indiceProblema = 0
    @State private var aciertosEnNivel = 0
    @State private var problemasActuales: [ProblemaMate] = []
    @State private var mensajeAnimacion = ""
    @State private var estrellasGanadasEnNivel = 0
    @State private var estrellasAntes = 0
    
    init(tipo: TipoOperacion, terminarSesion: @escaping (Int, Int) -> Void, alSalir: @escaping () -> Void) {
        self.tipo = tipo
        self.terminarSesion = terminarSesion
        self.alSalir = alSalir
        let clave = tipo == .resta ? "nivelRestaMaximo" : (tipo == .multiplicacion ? "nivelMultiMaximo" : "nivelDivMaximo")
        self._nivelMaximoDesbloqueado = AppStorage(wrappedValue: 1, clave)
    }
    
    var body: some View {
        ZStack {
            Color.crema.ignoresSafeArea()
            
            if let nivel = nivelSeleccionado {
                VStack(spacing: 24) {
                    // Barra superior
                    HStack {
                        Button(action: { nivelSeleccionado = nil }) {
                            HStack {
                                Image(systemName: "arrow.left.circle.fill")
                                Text("Niveles")
                            }
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.morado)
                        }
                        Spacer()
                        Text("Nivel \(nivel)")
                            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.morado)
                        Spacer()
                        // Progreso (3 por nivel)
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(i < aciertosEnNivel ? Color.verde : Color.morado.opacity(0.2))
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    if indiceProblema < problemasActuales.count {
                        let problema = problemasActuales[indiceProblema]
                        
                        // Tarjeta del Problema
                        VStack(spacing: 20) {
                            Text("\(problema.a)  \(problema.simbolo)  \(problema.b)  =  ?")
                                .font(.system(size: 70, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.morado)
                                .minimumScaleFactor(0.4)
                                .lineLimit(1)
                            
                            if !mensajeAnimacion.isEmpty {
                                Text(mensajeAnimacion)
                                    .font(.system(.title2, design: .rounded).weight(.bold))
                                    .foregroundStyle(mensajeAnimacion.contains("¡") ? Color.verde : Color.orange)
                            }
                        }
                        .padding(30)
                        .frame(maxWidth: 650)
                        .background(RoundedRectangle(cornerRadius: 30).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 30).stroke(tipo.colorBase, lineWidth: 6))
                        .shadow(color: tipo.colorBase.opacity(0.15), radius: 15, y: 8)
                        
                        Spacer()
                        
                        // Opciones múltiples
                        HStack(spacing: 24) {
                            ForEach(problema.opciones, id: \.self) { opcion in
                                Button(action: {
                                    verificarRespuesta(opcion, correcta: problema.respuestaCorrecta, nivel: nivel)
                                }) {
                                    Text("\(opcion)")
                                        .font(.system(size: 60, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Color.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                        .background(RoundedRectangle(cornerRadius: 24).fill(tipo.colorBase))
                                        .shadow(color: tipo.colorBase.opacity(0.3), radius: 5, y: 5)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 60)
                        .padding(.bottom, 40)
                    }
                }
                
            } else {
                // PANTALLA DE SELECCIÓN DE NIVELES (1 al 25)
                VStack(spacing: 20) {
                    HStack {
                        Button(action: alSalir) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.morado)
                        }
                        Spacer()
                        Text("\(tipo.emoji) \(tipo.tituloMenu)")
                            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.morado)
                        Spacer()
                        EstrellasJugador()
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 20)], spacing: 20) {
                            ForEach(1...25, id: \.self) { nivel in
                                let desbloqueado = nivel <= nivelMaximoDesbloqueado
                                
                                Button(action: {
                                    if desbloqueado {
                                        iniciarNivel(nivel)
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Text("\(nivel)")
                                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                                        
                                        Image(systemName: desbloqueado ? "star.fill" : "lock.fill")
                                            .font(.title3)
                                            .foregroundStyle(desbloqueado ? Color.amarillo : Color.gray)
                                    }
                                    .foregroundStyle(desbloqueado ? Color.morado : Color.gray)
                                    .frame(height: 110)
                                    .frame(maxWidth: .infinity)
                                    .background(RoundedRectangle(cornerRadius: 20).fill(desbloqueado ? Color.white : Color.white.opacity(0.5)))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(desbloqueado ? tipo.colorBase : Color.gray.opacity(0.5), lineWidth: 4))
                                    .shadow(color: tipo.colorBase.opacity(desbloqueado ? 0.1 : 0), radius: 8, y: 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(40)
                    }
                }
            }
        }
    }
    
    private func iniciarNivel(_ nivel: Int) {
        estrellasAntes = perfiles.activo?.estrellas ?? 0
        nivelSeleccionado = nivel
        indiceProblema = 0
        aciertosEnNivel = 0
        estrellasGanadasEnNivel = estrellasPorNivel(nivel)
        mensajeAnimacion = ""
        
        var lista: [ProblemaMate] = []
        for _ in 0..<3 {
            let (a, b) = generarNumeros(paraNivel: nivel)
            let tempProb = ProblemaMate(a: a, b: b, operacion: tipo, opciones: [])
            let correcta = tempProb.respuestaCorrecta
            
            var opcionesSet: Set<Int> = [correcta]
            while opcionesSet.count < 3 {
                let desviacion = Int.random(in: -3...3)
                let falsa = correcta + desviacion
                if falsa >= 0 && falsa != correcta {
                    opcionesSet.insert(falsa)
                } else {
                    opcionesSet.insert(correcta + Int.random(in: 1...4))
                }
            }
            lista.append(ProblemaMate(a: a, b: b, operacion: tipo, opciones: Array(opcionesSet).shuffled()))
        }
        problemasActuales = lista
    }
    
    private func generarNumeros(paraNivel nivel: Int) -> (Int, Int) {
        switch tipo {
        case .resta:
            let b = Int.random(in: 0...(nivel > 12 ? 10 : nivel / 2 + 1))
            let a = b + Int.random(in: 0...(nivel > 12 ? 10 : 5))
            return (max(a, b), min(a, b))
        case .multiplicacion:
            let maxFactor = min(nivel + 1, 10)
            let a = Int.random(in: 1...maxFactor)
            let b = Int.random(in: 1...5)
            return (a, b)
        case .division:
            let b = Int.random(in: 1...max(nivel / 2 + 1, 5))
            let cociente = Int.random(in: 1...5)
            let a = b * cociente
            return (a, b)
        }
    }
    
    private func verificarRespuesta(_ seleccionada: Int, correcta: Int, nivel: Int) {
        if seleccionada == correcta {
            aciertosEnNivel += 1
            mensajeAnimacion = "¡Muy bien! 🎉"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                mensajeAnimacion = ""
                if aciertosEnNivel >= 3 {
                    let premio = estrellasGanadasEnNivel
                    if let id = perfiles.activoID {
                        perfiles.sumarEstrellas(premio)
                    }
                    if nivel < 25 && nivel >= nivelMaximoDesbloqueado {
                        nivelMaximoDesbloqueado = nivel + 1
                    }
                    // Ir directo a la pantalla de piñata (CierreView)
                    terminarSesion(premio, estrellasAntes)
                } else {
                    indiceProblema += 1
                }
            }
        } else {
            mensajeAnimacion = "¡Casi, inténtalo de nuevo! 💡"
        }
    }
    
    private func estrellasPorNivel(_ nivel: Int) -> Int {
        if nivel <= 8 { return 1 }
        if nivel <= 16 { return 2 }
        return 3
    }
}
