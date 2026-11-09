import Foundation

enum PhysicsCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case mechanics
    case molecular
    case thermodynamics
    case electrodynamics
    case optics
    case oscillations
    case quantum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mechanics: "Механика"
        case .molecular: "Молекулярная физика"
        case .thermodynamics: "Термодинамика"
        case .electrodynamics: "Электродинамика"
        case .optics: "Оптика"
        case .oscillations: "Колебания и волны"
        case .quantum: "Квантовая физика"
        }
    }

    var systemImage: String {
        switch self {
        case .mechanics: "figure.walk.motion"
        case .molecular: "circle.hexagongrid.fill"
        case .thermodynamics: "thermometer.sun.fill"
        case .electrodynamics: "bolt.fill"
        case .optics: "camera.aperture"
        case .oscillations: "waveform.path"
        case .quantum: "atom"
        }
    }
}

struct PhysicsFormula: Identifiable, Hashable, Sendable {
    let category: PhysicsCategory
    let name: String
    let expression: String
    let variables: String
    let units: String
    let explanation: String
    let example: String

    var id: String { "\(category.rawValue).\(name)" }
}

enum FormulaDatabase {
    static var count: Int { formulas.count }

    static func formulas(for category: PhysicsCategory) -> [PhysicsFormula] {
        formulas.filter { $0.category == category }
    }

    static func search(_ query: String) -> [PhysicsFormula] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return formulas }
        return formulas.filter {
            $0.name.lowercased().contains(term)
                || $0.expression.lowercased().contains(term)
                || $0.variables.lowercased().contains(term)
                || $0.explanation.lowercased().contains(term)
                || $0.example.lowercased().contains(term)
                || $0.category.title.lowercased().contains(term)
        }
    }

    static let formulas: [PhysicsFormula] = mechanics + molecular + thermodynamics + electrodynamics + optics + oscillations + quantum

    private static let mechanics: [PhysicsFormula] = [
        PhysicsFormula(
            category: .mechanics,
            name: "Равномерное движение",
            expression: "s = vt",
            variables: "s — путь; v — скорость; t — время",
            units: "м; м/с; с",
            explanation: "При постоянной скорости путь прямо пропорционален времени движения.",
            example: "За 4 с при скорости 5 м/с тело пройдёт s = 5 · 4 = 20 м."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Скорость при равноускоренном движении",
            expression: "v = v_0 + at",
            variables: "v — конечная скорость; v₀ — начальная скорость; a — ускорение; t — время",
            units: "м/с; м/с; м/с²; с",
            explanation: "Скорость линейно меняется со временем, если ускорение постоянно.",
            example: "Из состояния покоя при a = 2 м/с² через 3 с: v = 0 + 2 · 3 = 6 м/с."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Координата при равноускоренном движении",
            expression: "x = x_0 + v_0t + \\frac{at^2}{2}",
            variables: "x — конечная координата; x₀ — начальная координата; v₀ — начальная скорость; a — ускорение; t — время",
            units: "м; м; м/с; м/с²; с",
            explanation: "Смещение складывается из равномерной части v₀t и вклада ускорения at²/2.",
            example: "При x₀ = 0, v₀ = 1 м/с, a = 2 м/с² за 2 с: x = 1·2 + 2·2²/2 = 6 м."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Связь скоростей и перемещения",
            expression: "v^2 - v_0^2 = 2as",
            variables: "v — конечная скорость; v₀ — начальная скорость; a — ускорение; s — перемещение",
            units: "м/с; м/с; м/с²; м",
            explanation: "Удобная формула, когда время движения неизвестно. Следует из исключения t из уравнений скорости и перемещения.",
            example: "Автомобиль тормозит от 20 до 0 м/с при a = −5 м/с²: 0 − 400 = 2·(−5)·s, s = 40 м."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Второй закон Ньютона",
            expression: "F = ma",
            variables: "F — равнодействующая сила; m — масса; a — ускорение",
            units: "Н; кг; м/с²",
            explanation: "Ускорение тела прямо пропорционально равнодействующей силе и обратно пропорционально массе. Записан для инерциальной системы отсчёта.",
            example: "Телу массой 2 кг сообщают ускорение 3 м/с² силой F = 2 · 3 = 6 Н."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Импульс тела",
            expression: "p = mv",
            variables: "p — импульс; m — масса; v — скорость",
            units: "кг·м/с; кг; м/с",
            explanation: "Импульс — векторная мера движения. Направление импульса совпадает с направлением скорости.",
            example: "Для m = 3 кг и v = 4 м/с: p = 3 · 4 = 12 кг·м/с."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Импульс силы",
            expression: "F\\Delta t = \\Delta p",
            variables: "F — сила; Δt — время действия; Δp — изменение импульса",
            units: "Н; с; кг·м/с",
            explanation: "Изменение импульса равно импульсу равнодействующей силы. Позволяет оценивать силы удара и торможения.",
            example: "Сила 100 Н действует 0,2 с: Δp = 100 · 0,2 = 20 кг·м/с."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Кинетическая энергия",
            expression: "E_k = \\frac{mv^2}{2}",
            variables: "Eₖ — кинетическая энергия; m — масса; v — скорость",
            units: "Дж; кг; м/с",
            explanation: "Энергия движения тела. При увеличении скорости вдвое кинетическая энергия возрастает в четыре раза.",
            example: "Для m = 2 кг и v = 3 м/с: Eₖ = 2 · 3² / 2 = 9 Дж."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Потенциальная энергия в поле тяжести",
            expression: "E_p = mgh",
            variables: "Eₚ — потенциальная энергия; m — масса; g — ускорение свободного падения; h — высота",
            units: "Дж; кг; м/с²; м",
            explanation: "Энергия взаимодействия тела с Землёй относительно выбранного уровня отсчёта.",
            example: "Тело 2 кг на высоте 5 м при g = 9,8 м/с²: Eₚ = 2 · 9,8 · 5 = 98 Дж."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Работа силы",
            expression: "A = Fs\\cos\\alpha",
            variables: "A — работа; F — сила; s — перемещение; α — угол между силой и перемещением",
            units: "Дж; Н; м; °",
            explanation: "Работа учитывает только составляющую силы вдоль перемещения. При α = 90° работа равна нулю.",
            example: "Сила 10 Н под углом 60° перемещает тело на 2 м: A = 10·2·0,5 = 10 Дж."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Мощность",
            expression: "N = \\frac{A}{t} = Fv",
            variables: "N — мощность; A — работа; t — время; F — сила; v — скорость",
            units: "Вт; Дж; с; Н; м/с",
            explanation: "Мощность показывает скорость совершения работы. При равномерном движении также равна произведению Fv.",
            example: "Работа 600 Дж выполнена за 3 с: N = 600 / 3 = 200 Вт."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Закон сохранения энергии",
            expression: "E_k + E_p = const",
            variables: "Eₖ — кинетическая энергия; Eₚ — потенциальная энергия",
            units: "Дж",
            explanation: "В замкнутой системе без неконсервативных сил полная механическая энергия сохраняется.",
            example: "Камень падает с высоты h: mgh переходит в mv²/2, поэтому v = √(2gh)."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Закон всемирного тяготения",
            expression: "F = G\\frac{m_1m_2}{r^2}",
            variables: "F — сила тяготения; G — гравитационная постоянная; m₁, m₂ — массы; r — расстояние",
            units: "Н; Н·м²/кг²; кг; м",
            explanation: "Сила взаимного притяжения двух точечных масс. G ≈ 6,67·10⁻¹¹ Н·м²/кг².",
            example: "Сила между массами 1 кг и 2 кг на расстоянии 1 м: F ≈ 1,33·10⁻¹⁰ Н."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Ускорение свободного падения",
            expression: "g = G\\frac{M}{R^2}",
            variables: "g — ускорение свободного падения; M — масса планеты; R — её радиус; G — гравитационная постоянная",
            units: "м/с²; кг; м",
            explanation: "Вблизи поверхности планеты ускорение зависит от её массы и радиуса. Для Земли g ≈ 9,8 м/с².",
            example: "На Луне M и R меньше, поэтому g ≈ 1,6 м/с²."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Сила трения",
            expression: "F_{\\text{тр}} = \\mu N",
            variables: "Fтр — сила трения; μ — коэффициент трения; N — сила нормального давления",
            units: "Н; безразмерный; Н",
            explanation: "Для сухого трения скольжения сила трения пропорциональна нормальной реакции, но не площади контакта.",
            example: "При N = 50 Н и μ = 0,2: Fтр = 0,2 · 50 = 10 Н."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Центростремительное ускорение",
            expression: "a_ц = \\frac{v^2}{r} = \\omega^2r",
            variables: "aц — центростремительное ускорение; v — линейная скорость; r — радиус; ω — угловая скорость",
            units: "м/с²; м/с; м; рад/с",
            explanation: "Ускорение при равномерном движении по окружности направлено к её центру и меняет направление скорости.",
            example: "При v = 4 м/с и r = 2 м: aц = 16/2 = 8 м/с²."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Угловая скорость и период",
            expression: "\\omega = \\frac{2\\pi}{T} = 2\\pi\\nu",
            variables: "ω — угловая скорость; T — период; ν — частота",
            units: "рад/с; с; Гц",
            explanation: "Угловая скорость показывает угол поворота за единицу времени. Линейная скорость v = ωr.",
            example: "При периоде 0,5 с: ω = 2π/0,5 = 4π ≈ 12,6 рад/с."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Давление",
            expression: "p = \\frac{F}{S}",
            variables: "p — давление; F — сила давления; S — площадь поверхности",
            units: "Па; Н; м²",
            explanation: "Давление равно нормальной силе, действующей на единицу площади.",
            example: "Сила 100 Н на площадь 0,5 м² создаёт давление p = 100/0,5 = 200 Па."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Гидростатическое давление",
            expression: "p = \\rho gh",
            variables: "p — давление; ρ — плотность жидкости; g — ускорение свободного падения; h — глубина",
            units: "Па; кг/м³; м/с²; м",
            explanation: "Давление столба жидкости зависит от плотности, глубины и g, но не от формы сосуда.",
            example: "На глубине 2 м в воде (ρ = 1000 кг/м³): p ≈ 1000·9,8·2 = 19 600 Па."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Архимедова сила",
            expression: "F_A = \\rho_{\\text{ж}}gV",
            variables: "F_A — выталкивающая сила; ρж — плотность жидкости; g — ускорение свободного падения; V — объём погружённой части",
            units: "Н; кг/м³; м/с²; м³",
            explanation: "Выталкивающая сила равна весу вытесненной жидкости. Тело плавает, если средняя плотность меньше плотности жидкости.",
            example: "Тело объёмом 0,002 м³ в воде: F_A ≈ 1000·9,8·0,002 = 19,6 Н."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "Момент силы",
            expression: "M = Fl",
            variables: "M — момент силы; F — сила; l — плечо силы",
            units: "Н·м; Н; м",
            explanation: "Момент силы характеризует её вращающее действие. Плечо — кратчайшее расстояние от оси до линии действия силы.",
            example: "Сила 20 Н на плече 0,5 м создаёт момент 10 Н·м."
        ),
        PhysicsFormula(
            category: .mechanics,
            name: "КПД механизма",
            expression: "\\eta = \\frac{A_{\\text{полезн}}}{A_{\\text{затр}}} \\cdot 100\\%",
            variables: "η — КПД; Aполезн — полезная работа; Aзатр — затраченная работа",
            units: "% (или безразмерный); Дж; Дж",
            explanation: "КПД показывает, какая часть затраченной работы превратилась в полезную. Всегда меньше 100% для реального механизма.",
            example: "Из 500 Дж затраченной работы полезно использовано 400 Дж: η = 80%."
        )
    ]

    private static let molecular: [PhysicsFormula] = [
        PhysicsFormula(
            category: .molecular,
            name: "Количество вещества",
            expression: "\\nu = \\frac{N}{N_A} = \\frac{m}{M}",
            variables: "ν — количество вещества; N — число молекул; N_A — постоянная Авогадро; m — масса; M — молярная масса",
            units: "моль; —; 6,022·10²³ моль⁻¹; кг; кг/моль",
            explanation: "Количество вещества связывает число частиц и массу. N_A ≈ 6,022·10²³ моль⁻¹.",
            example: "18 г воды (M = 0,018 кг/моль): ν = 0,018/0,018 = 1 моль."
        ),
        PhysicsFormula(
            category: .molecular,
            name: "Концентрация молекул",
            expression: "n = \\frac{N}{V}",
            variables: "n — концентрация; N — число молекул; V — объём",
            units: "м⁻³; —; м³",
            explanation: "Концентрация показывает число частиц в единице объёма.",
            example: "10²⁴ молекул в 0,5 м³ дают n = 2·10²⁴ м⁻³."
        ),
        PhysicsFormula(
            category: .molecular,
            name: "Основное уравнение МКТ",
            expression: "p = \\frac{1}{3}m_0nv^2",
            variables: "p — давление газа; m₀ — масса молекулы; n — концентрация; v² — средний квадрат скорости",
            units: "Па; кг; м⁻³; м²/с²",
            explanation: "Давление идеального газа объясняется ударами молекул о стенки сосуда.",
            example: "Увеличение концентрации вдвое при той же температуре удваивает давление."
        ),
        PhysicsFormula(
            category: .molecular,
            name: "Средняя кинетическая энергия молекулы",
            expression: "\\overline{E}_k = \\frac{3}{2}kT",
            variables: "Ēₖ — средняя кинетическая энергия; k — постоянная Больцмана; T — абсолютная температура",
            units: "Дж; 1,38·10⁻²³ Дж/К; К",
            explanation: "Средняя энергия поступательного движения молекулы зависит только от абсолютной температуры.",
            example: "При T = 300 К: Ēₖ = 1,5·1,38·10⁻²³·300 ≈ 6,2·10⁻²¹ Дж."
        ),
        PhysicsFormula(
            category: .molecular,
            name: "Уравнение состояния идеального газа",
            expression: "pV = \\nu RT",
            variables: "p — давление; V — объём; ν — количество вещества; R — универсальная газовая постоянная; T — температура",
            units: "Па; м³; моль; 8,31 Дж/(моль·К); К",
            explanation: "Уравнение Менделеева — Клапейрона связывает макропараметры идеального газа. Температура обязательно в кельвинах.",
            example: "1 моль при 300 К и объёме 0,025 м³: p ≈ 8,31·300/0,025 ≈ 99 700 Па."
        ),
        PhysicsFormula(
            category: .molecular,
            name: "Средняя квадратичная скорость",
            expression: "v_{\\text{кв}} = \\sqrt{\\frac{3kT}{m_0}} = \\sqrt{\\frac{3RT}{M}}",
            variables: "vкв — средняя квадратичная скорость; k — постоянная Больцмана; T — температура; m₀ — масса молекулы; M — молярная масса",
            units: "м/с; Дж/К; К; кг; кг/моль",
            explanation: "Более лёгкие молекулы при той же температуре движутся быстрее.",
            example: "Для водорода при 300 К: vкв = √(3·8,31·300/0,002) ≈ 1,93 км/с."
        ),
        PhysicsFormula(
            category: .molecular,
            name: "Связь давления и концентрации",
            expression: "p = nkT",
            variables: "p — давление; n — концентрация; k — постоянная Больцмана; T — абсолютная температура",
            units: "Па; м⁻³; Дж/К; К",
            explanation: "Давление идеального газа пропорционально концентрации и абсолютной температуре.",
            example: "При n = 2,4·10²⁵ м⁻³ и T = 300 К: p ≈ 10⁵ Па."
        ),
        PhysicsFormula(
            category: .molecular,
            name: "Закон Дальтона",
            expression: "p = p_1 + p_2 + \\dots + p_n",
            variables: "p — общее давление смеси; pᵢ — парциальное давление компонента",
            units: "Па",
            explanation: "Давление смеси невзаимодействующих газов равно сумме их парциальных давлений.",
            example: "Смесь кислорода (20 кПа) и азота (80 кПа) даёт 100 кПа."
        ),
        PhysicsFormula(
            category: .molecular,
            name: "Относительная влажность",
            expression: "\\varphi = \\frac{\\rho}{\\rho_{\\text{нас}}} \\cdot 100\\%",
            variables: "φ — относительная влажность; ρ — абсолютная плотность пара; ρнас — плотность насыщенного пара при той же температуре; можно заменить ρ на парциальное давление",
            units: "% (или безразмерный); кг/м³; кг/м³",
            explanation: "Относительная влажность показывает, насколько водяной пар близок к насыщению.",
            example: "При ρ = 8,3 г/м³ и ρнас = 16,6 г/м³: φ = 50%."
        )
    ]

    private static let thermodynamics: [PhysicsFormula] = [
        PhysicsFormula(
            category: .thermodynamics,
            name: "Внутренняя энергия одноатомного газа",
            expression: "U = \\frac{3}{2}\\nu RT",
            variables: "U — внутренняя энергия; ν — количество вещества; R — универсальная газовая постоянная; T — температура",
            units: "Дж; моль; Дж/(моль·К); К",
            explanation: "Формула для идеального одноатомного газа. Для двухатомного газа коэффициент зависит от числа степеней свободы.",
            example: "Для 2 моль при 300 К: U = 1,5·2·8,31·300 ≈ 7,48 кДж."
        ),
        PhysicsFormula(
            category: .thermodynamics,
            name: "Первый закон термодинамики",
            expression: "Q = \\Delta U + A",
            variables: "Q — переданная теплота; ΔU — изменение внутренней энергии; A — работа газа",
            units: "Дж",
            explanation: "Запись для работы, совершаемой газом. Теплота идёт на изменение внутренней энергии и работу газа.",
            example: "Газ получил 500 Дж и совершил 200 Дж работы: ΔU = 300 Дж."
        ),
        PhysicsFormula(
            category: .thermodynamics,
            name: "Работа газа при изобарном процессе",
            expression: "A = p\\Delta V",
            variables: "A — работа газа; p — давление; ΔV — изменение объёма",
            units: "Дж; Па; м³",
            explanation: "При постоянном давлении работа газа пропорциональна изменению объёма.",
            example: "При p = 10⁵ Па и ΔV = 0,002 м³: A = 200 Дж."
        ),
        PhysicsFormula(
            category: .thermodynamics,
            name: "Количество теплоты при нагревании",
            expression: "Q = cm\\Delta T",
            variables: "Q — теплота; c — удельная теплоёмкость; m — масса; ΔT — изменение температуры",
            units: "Дж; Дж/(кг·К); кг; К",
            explanation: "Теплота, необходимая для нагревания тела без изменения агрегатного состояния.",
            example: "2 кг воды нагрели на 10 К (c ≈ 4200): Q = 4200·2·10 = 84 кДж."
        ),
        PhysicsFormula(
            category: .thermodynamics,
            name: "Теплота плавления",
            expression: "Q = \\lambda m",
            variables: "Q — теплота; λ — удельная теплота плавления; m — масса",
            units: "Дж; Дж/кг; кг",
            explanation: "Количество теплоты, необходимое для плавления кристаллического тела при температуре плавления.",
            example: "Для плавления 0,5 кг льда (λ ≈ 3,34·10⁵ Дж/кг): Q ≈ 167 кДж."
        ),
        PhysicsFormula(
            category: .thermodynamics,
            name: "Теплота парообразования",
            expression: "Q = Lm",
            variables: "Q — теплота; L — удельная теплота парообразования; m — масса",
            units: "Дж; Дж/кг; кг",
            explanation: "Теплота, необходимая для превращения жидкости в пар при температуре кипения.",
            example: "Для 0,2 кг воды при 100 °C (L ≈ 2,3·10⁶ Дж/кг): Q ≈ 460 кДж."
        ),
        PhysicsFormula(
            category: .thermodynamics,
            name: "Теплота сгорания топлива",
            expression: "Q = qm",
            variables: "Q — выделившаяся теплота; q — удельная теплота сгорания; m — масса топлива",
            units: "Дж; Дж/кг; кг",
            explanation: "Энергия, выделяющаяся при полном сгорании топлива.",
            example: "При сгорании 2 кг топлива с q = 4,6·10⁷ Дж/кг выделяется 92 МДж."
        ),
        PhysicsFormula(
            category: .thermodynamics,
            name: "КПД теплового двигателя",
            expression: "\\eta = \\frac{Q_1 - Q_2}{Q_1}",
            variables: "η — КПД; Q₁ — теплота от нагревателя; Q₂ — теплота холодильнику",
            units: "% (или безразмерный); Дж; Дж",
            explanation: "КПД показывает долю теплоты нагревателя, превращённую в полезную работу.",
            example: "Q₁ = 1000 Дж, Q₂ = 600 Дж: η = 40%."
        ),
        PhysicsFormula(
            category: .thermodynamics,
            name: "КПД цикла Карно",
            expression: "\\eta = 1 - \\frac{T_2}{T_1}",
            variables: "η — максимальный КПД; T₁ — температура нагревателя; T₂ — температура холодильника",
            units: "% (или безразмерный); К; К",
            explanation: "Предельный КПД идеальной тепловой машины, работающей по обратимому циклу Карно. Температуры задаются в кельвинах.",
            example: "T₁ = 500 К, T₂ = 300 К: η = 1 − 0,6 = 40%."
        ),
        PhysicsFormula(
            category: .thermodynamics,
            name: "Уравнение теплового баланса",
            expression: "Q_{\\text{отд}} = Q_{\\text{пол}}",
            variables: "Qотд — теплота, отданная телами; Qпол — теплота, полученная телами",
            units: "Дж",
            explanation: "В теплоизолированной системе суммарная переданная теплота равна полученной, если нет фазовых переходов с потерями.",
            example: "Горячая вода отдала 10 кДж, значит холодная вода и калориметр получили 10 кДж."
        )
    ]

    private static let electrodynamics: [PhysicsFormula] = [
        PhysicsFormula(
            category: .electrodynamics,
            name: "Закон Кулона",
            expression: "F = k\\frac{|q_1q_2|}{r^2}",
            variables: "F — сила взаимодействия; k — электрическая постоянная; q₁, q₂ — заряды; r — расстояние",
            units: "Н; Н·м²/Кл²; Кл; м",
            explanation: "Сила взаимодействия точечных зарядов. k ≈ 9·10⁹ Н·м²/Кл²; направление силы зависит от знаков зарядов.",
            example: "Два заряда по 1 мкКл на расстоянии 0,1 м: F ≈ 0,9 Н."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Напряжённость электрического поля",
            expression: "E = \\frac{F}{q}",
            variables: "E — напряжённость; F — сила, действующая на заряд; q — пробный заряд",
            units: "В/м; Н; Кл",
            explanation: "Напряжённость — силовая характеристика поля. Для поля точечного заряда E = k|Q|/r².",
            example: "На заряд 2·10⁻⁶ Кл действует сила 0,01 Н: E = 5000 В/м."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Потенциал электрического поля",
            expression: "\\varphi = \\frac{W_p}{q}",
            variables: "φ — потенциал; Wₚ — потенциальная энергия заряда; q — заряд",
            units: "В; Дж; Кл",
            explanation: "Потенциал — энергетическая характеристика поля в точке.",
            example: "Заряд 2 Кл обладает потенциальной энергией 10 Дж: φ = 5 В."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Напряжение",
            expression: "U = \\frac{A}{q}",
            variables: "U — напряжение; A — работа электрического поля; q — заряд",
            units: "В; Дж; Кл",
            explanation: "Напряжение равно работе электрического поля при перемещении единичного заряда.",
            example: "При переносе 3 Кл поле совершает 12 Дж работы: U = 4 В."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Электроёмкость",
            expression: "C = \\frac{q}{U}",
            variables: "C — электроёмкость; q — заряд конденсатора; U — напряжение",
            units: "Ф; Кл; В",
            explanation: "Электроёмкость показывает, какой заряд накапливается при напряжении 1 В.",
            example: "При напряжении 10 В конденсатор накопил 2·10⁻⁵ Кл: C = 2 мкФ."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Ёмкость плоского конденсатора",
            expression: "C = \\frac{\\varepsilon\\varepsilon_0S}{d}",
            variables: "C — ёмкость; ε — диэлектрическая проницаемость; ε₀ — электрическая постоянная; S — площадь пластин; d — расстояние",
            units: "Ф; —; 8,85·10⁻¹² Ф/м; м²; м",
            explanation: "Ёмкость растёт с площадью пластин и проницаемостью и уменьшается с увеличением расстояния.",
            example: "Увеличение расстояния вдвое уменьшает ёмкость вдвое."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Энергия конденсатора",
            expression: "W = \\frac{CU^2}{2} = \\frac{qU}{2}",
            variables: "W — энергия; C — ёмкость; U — напряжение; q — заряд",
            units: "Дж; Ф; В; Кл",
            explanation: "Энергия электрического поля заряженного конденсатора.",
            example: "C = 10 мкФ, U = 100 В: W = 10⁻⁵·10⁴/2 = 0,05 Дж."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Сила тока",
            expression: "I = \\frac{q}{t}",
            variables: "I — сила тока; q — заряд, прошедший через сечение; t — время",
            units: "А; Кл; с",
            explanation: "Сила тока — заряд, проходящий через поперечное сечение проводника за единицу времени.",
            example: "За 5 с прошло 10 Кл: I = 2 А."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Закон Ома для участка цепи",
            expression: "I = \\frac{U}{R}",
            variables: "I — сила тока; U — напряжение; R — сопротивление",
            units: "А; В; Ом",
            explanation: "При постоянной температуре сила тока пропорциональна напряжению и обратно пропорциональна сопротивлению.",
            example: "При U = 12 В и R = 6 Ом: I = 2 А."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Сопротивление проводника",
            expression: "R = \\rho\\frac{l}{S}",
            variables: "R — сопротивление; ρ — удельное сопротивление; l — длина; S — площадь сечения",
            units: "Ом; Ом·м; м; м²",
            explanation: "Сопротивление растёт с длиной и уменьшается с площадью поперечного сечения.",
            example: "Увеличение длины провода вдвое удваивает его сопротивление."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Последовательное соединение",
            expression: "R = R_1 + R_2 + \\dots + R_n",
            variables: "R — общее сопротивление; Rᵢ — сопротивления участков",
            units: "Ом",
            explanation: "При последовательном соединении сила тока одинакова, а напряжения складываются.",
            example: "Резисторы 3 Ом и 7 Ом последовательно дают 10 Ом."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Параллельное соединение",
            expression: "\\frac{1}{R} = \\frac{1}{R_1} + \\frac{1}{R_2} + \\dots + \\frac{1}{R_n}",
            variables: "R — общее сопротивление; Rᵢ — сопротивления ветвей",
            units: "Ом",
            explanation: "При параллельном соединении напряжение одинаково, а токи складываются. Общее сопротивление меньше наименьшего из сопротивлений.",
            example: "Два резистора по 4 Ом параллельно дают 2 Ом."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Работа электрического тока",
            expression: "A = UIt",
            variables: "A — работа; U — напряжение; I — сила тока; t — время",
            units: "Дж; В; А; с",
            explanation: "Работа тока на участке цепи при постоянных U и I.",
            example: "При U = 220 В, I = 2 А за 10 с: A = 4400 Дж."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Мощность электрического тока",
            expression: "P = UI = I^2R = \\frac{U^2}{R}",
            variables: "P — мощность; U — напряжение; I — сила тока; R — сопротивление",
            units: "Вт; В; А; Ом",
            explanation: "Выбор формы зависит от известных величин. Для последовательной цепи удобна I²R, для параллельной — U²/R.",
            example: "При U = 12 В и I = 2 А: P = 24 Вт."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Закон Джоуля — Ленца",
            expression: "Q = I^2Rt",
            variables: "Q — теплота; I — сила тока; R — сопротивление; t — время",
            units: "Дж; А; Ом; с",
            explanation: "Количество теплоты, выделяемое проводником с током.",
            example: "При I = 2 А, R = 5 Ом, t = 10 с: Q = 4·5·10 = 200 Дж."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Закон Ампера",
            expression: "F_A = BIl\\sin\\alpha",
            variables: "F_A — сила Ампера; B — магнитная индукция; I — сила тока; l — длина проводника; α — угол с полем",
            units: "Н; Тл; А; м; °",
            explanation: "Сила, действующая на прямолинейный проводник с током в магнитном поле.",
            example: "B = 0,5 Тл, I = 2 А, l = 0,4 м, α = 90°: F = 0,4 Н."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Сила Лоренца",
            expression: "F_L = qvB\\sin\\alpha",
            variables: "F_L — сила Лоренца; q — заряд; v — скорость; B — магнитная индукция; α — угол",
            units: "Н; Кл; м/с; Тл; °",
            explanation: "Сила, с которой магнитное поле действует на движущийся заряд. Перпендикулярна скорости и полю.",
            example: "Заряд 1 мкКл, v = 10⁵ м/с, B = 1 Тл, α = 90°: F = 0,1 Н."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Магнитный поток",
            expression: "\\Phi = BS\\cos\\alpha",
            variables: "Φ — магнитный поток; B — индукция; S — площадь контура; α — угол между нормалью и полем",
            units: "Вб; Тл; м²; °",
            explanation: "Магнитный поток через контур. Максимален, когда поле перпендикулярно плоскости контура.",
            example: "B = 0,2 Тл, S = 0,5 м², α = 0°: Φ = 0,1 Вб."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Закон электромагнитной индукции",
            expression: "\\varepsilon_i = -\\frac{\\Delta\\Phi}{\\Delta t}",
            variables: "εᵢ — ЭДС индукции; ΔΦ — изменение магнитного потока; Δt — время",
            units: "В; Вб; с",
            explanation: "ЭДС индукции пропорциональна скорости изменения магнитного потока. Знак отражает правило Ленца.",
            example: "Поток изменился на 0,02 Вб за 0,1 с: |ε| = 0,2 В."
        ),
        PhysicsFormula(
            category: .electrodynamics,
            name: "Энергия магнитного поля катушки",
            expression: "W = \\frac{LI^2}{2}",
            variables: "W — энергия; L — индуктивность; I — сила тока",
            units: "Дж; Гн; А",
            explanation: "Магнитная энергия катушки с током. Аналогична энергии заряженного конденсатора.",
            example: "При L = 0,2 Гн и I = 3 А: W = 0,2·9/2 = 0,9 Дж."
        )
    ]

    private static let optics: [PhysicsFormula] = [
        PhysicsFormula(
            category: .optics,
            name: "Закон отражения света",
            expression: "\\alpha = \\beta",
            variables: "α — угол падения; β — угол отражения",
            units: "°",
            explanation: "Падающий и отражённый лучи лежат в одной плоскости с нормалью, а углы равны.",
            example: "При угле падения 35° отражённый луч также идёт под углом 35° к нормали."
        ),
        PhysicsFormula(
            category: .optics,
            name: "Абсолютный показатель преломления",
            expression: "n = \\frac{c}{v}",
            variables: "n — показатель преломления; c — скорость света в вакууме; v — скорость света в среде",
            units: "безразмерный; м/с; м/с",
            explanation: "Показывает, во сколько раз свет в среде медленнее, чем в вакууме. Для воды n ≈ 1,33.",
            example: "Если v = 2·10⁸ м/с, то n = 3·10⁸/2·10⁸ = 1,5."
        ),
        PhysicsFormula(
            category: .optics,
            name: "Закон преломления света",
            expression: "n_1\\sin\\alpha = n_2\\sin\\beta",
            variables: "n₁, n₂ — показатели преломления сред; α — угол падения; β — угол преломления",
            units: "безразмерный; °",
            explanation: "Закон Снеллиуса. При переходе в более плотную среду луч отклоняется к нормали.",
            example: "Из воздуха (n = 1) в стекло (n = 1,5) при α = 30°: sin β = 1/3, β ≈ 19,5°."
        ),
        PhysicsFormula(
            category: .optics,
            name: "Полное внутреннее отражение",
            expression: "\\sin\\alpha_0 = \\frac{n_2}{n_1}",
            variables: "α₀ — предельный угол; n₁ — оптически более плотная среда; n₂ — менее плотная среда",
            units: "°; безразмерный",
            explanation: "При переходе из оптически более плотной среды в менее плотную под углом больше предельного свет не выходит наружу.",
            example: "Для стекла (1,5) и воздуха (1): sin α₀ = 2/3, α₀ ≈ 41,8°."
        ),
        PhysicsFormula(
            category: .optics,
            name: "Формула тонкой линзы",
            expression: "\\frac{1}{F} = \\frac{1}{d} + \\frac{1}{f}",
            variables: "F — фокусное расстояние; d — расстояние до предмета; f — расстояние до изображения",
            units: "м; м; м",
            explanation: "Для действительного изображения, создаваемого собирающей линзой, при принятых знаках. Рассеивающая линза требует учёта знаков.",
            example: "При d = 30 см и F = 10 см: 1/f = 1/10 − 1/30, f = 15 см."
        ),
        PhysicsFormula(
            category: .optics,
            name: "Оптическая сила линзы",
            expression: "D = \\frac{1}{F}",
            variables: "D — оптическая сила; F — фокусное расстояние",
            units: "дптр; м",
            explanation: "Оптическая сила собирающей линзы положительна, рассеивающей — отрицательна.",
            example: "Фокусное расстояние 0,25 м соответствует D = 4 дптр."
        ),
        PhysicsFormula(
            category: .optics,
            name: "Увеличение линзы",
            expression: "\\Gamma = \\frac{f}{d} = \\frac{H}{h}",
            variables: "Γ — линейное увеличение; f — расстояние до изображения; d — до предмета; H, h — размеры",
            units: "безразмерный; м",
            explanation: "Показывает, во сколько раз размер изображения больше размера предмета.",
            example: "Если f/d = 2, изображение в два раза больше предмета."
        ),
        PhysicsFormula(
            category: .optics,
            name: "Дифракционная решётка",
            expression: "d\\sin\\varphi = k\\lambda",
            variables: "d — период решётки; φ — угол наблюдения максимума; k — порядок спектра; λ — длина волны",
            units: "м; °; —; м",
            explanation: "Условие главных дифракционных максимумов.",
            example: "При λ = 500 нм, d = 2 мкм, k = 1: sin φ = 0,25, φ ≈ 14,5°."
        ),
        PhysicsFormula(
            category: .optics,
            name: "Интерференционный максимум",
            expression: "\\Delta d = k\\lambda",
            variables: "Δd — разность хода; k — целое число; λ — длина волны",
            units: "м; —; м",
            explanation: "Условие усиления волн при интерференции. Для минимума разность хода равна (k + ½)λ.",
            example: "При разности хода 2λ волны приходят в фазе и усиливают друг друга."
        )
    ]

    private static let oscillations: [PhysicsFormula] = [
        PhysicsFormula(
            category: .oscillations,
            name: "Период и частота",
            expression: "T = \\frac{1}{\\nu}",
            variables: "T — период; ν — частота",
            units: "с; Гц",
            explanation: "Период — время одного полного колебания, частота — число колебаний за секунду.",
            example: "Частота 5 Гц соответствует периоду T = 0,2 с."
        ),
        PhysicsFormula(
            category: .oscillations,
            name: "Циклическая частота",
            expression: "\\omega = \\frac{2\\pi}{T} = 2\\pi\\nu",
            variables: "ω — круговая частота; T — период; ν — частота",
            units: "рад/с; с; Гц",
            explanation: "Связывает периодическое движение с угловой частотой колебательной системы.",
            example: "Для T = 0,5 с: ω = 4π ≈ 12,57 рад/с."
        ),
        PhysicsFormula(
            category: .oscillations,
            name: "Период математического маятника",
            expression: "T = 2\\pi\\sqrt{\\frac{l}{g}}",
            variables: "T — период малых колебаний; l — длина нити; g — ускорение свободного падения",
            units: "с; м; м/с²",
            explanation: "Справедлива для малых углов отклонения. Период не зависит от массы груза.",
            example: "Для l = 1 м и g ≈ 9,8 м/с²: T ≈ 2,0 с."
        ),
        PhysicsFormula(
            category: .oscillations,
            name: "Период пружинного маятника",
            expression: "T = 2\\pi\\sqrt{\\frac{m}{k}}",
            variables: "T — период; m — масса груза; k — жёсткость пружины",
            units: "с; кг; Н/м",
            explanation: "При малых упругих деформациях. Чем больше масса и меньше жёсткость, тем больше период.",
            example: "При m = 0,5 кг и k = 50 Н/м: T = 2π·0,1 = 0,63 с."
        ),
        PhysicsFormula(
            category: .oscillations,
            name: "Уравнение гармонических колебаний",
            expression: "x = A\\cos(\\omega t + \\varphi_0)",
            variables: "x — координата; A — амплитуда; ω — циклическая частота; t — время; φ₀ — начальная фаза",
            units: "м; м; рад/с; с; рад",
            explanation: "Описывает смещение при гармонических колебаниях. Амплитуда — максимальное отклонение.",
            example: "При A = 0,1 м, ω = 2 рад/с и φ₀ = 0 в момент t = 0 координата равна 0,1 м."
        ),
        PhysicsFormula(
            category: .oscillations,
            name: "Скорость гармонических колебаний",
            expression: "v = -A\\omega\\sin(\\omega t + \\varphi_0)",
            variables: "v — скорость; A — амплитуда; ω — частота; φ₀ — начальная фаза",
            units: "м/с; м; рад/с",
            explanation: "Скорость максимальна при прохождении положения равновесия и равна нулю в крайних точках.",
            example: "Максимальная скорость колебаний v_max = Aω."
        ),
        PhysicsFormula(
            category: .oscillations,
            name: "Ускорение гармонических колебаний",
            expression: "a = -\\omega^2x",
            variables: "a — ускорение; ω — циклическая частота; x — смещение",
            units: "м/с²; рад/с; м",
            explanation: "Ускорение направлено к положению равновесия и пропорционально смещению.",
            example: "При ω = 2 рад/с и x = 0,1 м: a = −0,4 м/с²."
        ),
        PhysicsFormula(
            category: .oscillations,
            name: "Длина волны",
            expression: "\\lambda = vT = \\frac{v}{\\nu}",
            variables: "λ — длина волны; v — скорость волны; T — период; ν — частота",
            units: "м; м/с; с; Гц",
            explanation: "Длина волны — расстояние между соседними точками в одинаковой фазе.",
            example: "При v = 340 м/с и ν = 680 Гц: λ = 0,5 м."
        ),
        PhysicsFormula(
            category: .oscillations,
            name: "Энергия пружинного маятника",
            expression: "W = \\frac{kA^2}{2}",
            variables: "W — полная энергия колебаний; k — жёсткость; A — амплитуда",
            units: "Дж; Н/м; м",
            explanation: "При отсутствии потерь энергия переходит между кинетической и потенциальной, но остаётся постоянной.",
            example: "При k = 100 Н/м и A = 0,1 м: W = 0,5 Дж."
        )
    ]

    private static let quantum: [PhysicsFormula] = [
        PhysicsFormula(
            category: .quantum,
            name: "Энергия фотона",
            expression: "E = h\\nu = \\frac{hc}{\\lambda}",
            variables: "E — энергия фотона; h — постоянная Планка; ν — частота; c — скорость света; λ — длина волны",
            units: "Дж (или эВ); 6,626·10⁻³⁴ Дж·с; Гц; м",
            explanation: "Энергия кванта света пропорциональна частоте. h ≈ 6,626·10⁻³⁴ Дж·с.",
            example: "Фотон с λ = 500 нм имеет E = hc/λ ≈ 3,97·10⁻¹⁹ Дж ≈ 2,48 эВ."
        ),
        PhysicsFormula(
            category: .quantum,
            name: "Импульс фотона",
            expression: "p = \\frac{h}{\\lambda}",
            variables: "p — импульс фотона; h — постоянная Планка; λ — длина волны",
            units: "кг·м/с; Дж·с; м",
            explanation: "Фотон не имеет массы покоя, но переносит импульс.",
            example: "Для λ = 500 нм: p ≈ 1,33·10⁻²⁷ кг·м/с."
        ),
        PhysicsFormula(
            category: .quantum,
            name: "Уравнение Эйнштейна для фотоэффекта",
            expression: "h\\nu = A_{\\text{вых}} + E_{k\\max}",
            variables: "hν — энергия фотона; Aвых — работа выхода; E_kmax — максимальная кинетическая энергия фотоэлектрона",
            units: "Дж (или эВ)",
            explanation: "Фотон передаёт электрону энергию; часть идёт на работу выхода, остаток — на кинетическую энергию.",
            example: "Фотон 3 эВ, работа выхода 1,5 эВ: E_kmax = 1,5 эВ."
        ),
        PhysicsFormula(
            category: .quantum,
            name: "Красная граница фотоэффекта",
            expression: "\\nu_{\\min} = \\frac{A_{\\text{вых}}}{h}",
            variables: "νmin — минимальная частота света; Aвых — работа выхода; h — постоянная Планка",
            units: "Гц; Дж; Дж·с",
            explanation: "Фотоэффект возникает только при достаточной частоте света, независимо от интенсивности.",
            example: "Чем больше работа выхода, тем выше красная граница."
        ),
        PhysicsFormula(
            category: .quantum,
            name: "Волна де Бройля",
            expression: "\\lambda = \\frac{h}{p} = \\frac{h}{mv}",
            variables: "λ — длина волны; h — постоянная Планка; p — импульс; m — масса; v — скорость",
            units: "м; Дж·с; кг·м/с",
            explanation: "Каждой частице соответствует волновой процесс. Для макроскопических тел длина волны крайне мала.",
            example: "Для электрона с p = 10⁻²⁴ кг·м/с: λ ≈ 6,6·10⁻¹⁰ м."
        ),
        PhysicsFormula(
            category: .quantum,
            name: "Уровни энергии атома водорода",
            expression: "E_n = -\\frac{13{,}6}{n^2}\\ \\text{эВ}",
            variables: "Eₙ — энергия уровня; n — главное квантовое число",
            units: "эВ; —",
            explanation: "Энергия связанного электрона в атоме водорода отрицательна; нулевой уровень соответствует свободному электрону.",
            example: "Основное состояние n = 1: E₁ = −13,6 эВ."
        ),
        PhysicsFormula(
            category: .quantum,
            name: "Закон радиоактивного распада",
            expression: "N = N_0 2^{-t/T}",
            variables: "N — число нераспавшихся ядер; N₀ — начальное число; t — время; T — период полураспада",
            units: "—; —; с; с",
            explanation: "За каждый период полураспада остаётся половина нераспавшихся ядер.",
            example: "Через два периода полураспада останется N₀/4 ядер."
        ),
        PhysicsFormula(
            category: .quantum,
            name: "Связь массы и энергии",
            expression: "E = mc^2",
            variables: "E — полная энергия; m — масса; c — скорость света",
            units: "Дж; кг; м/с",
            explanation: "Масса и энергия связаны. Изменение энергии системы сопровождается изменением её массы.",
            example: "1 г массы соответствует энергии E = 10⁻³ · (3·10⁸)² = 9·10¹³ Дж."
        )
    ]
}
