//: SwiftUI based Playground for presenting user interface
  
import UIKit
import SwiftUI
import PlaygroundSupport

// 建立灯的模型
struct Light {
    // 灯的状态默认关闭
    var status = Bool.random()
}

// 建立游戏数据模型
class GameManager: ObservableObject {
    
    
    @Published var lights = [[Light]]()
    @Published var clickTimes = 0
    // 设置游戏尺寸大小
    private(set) var size: Int?
    /// 对外发布的格式化计时器字符串
    @Published var timeString = "00:00"


    /// 游戏计时器
    private var timer: Timer?
    func timerStop() {
        timer?.invalidate()
        timer = nil
    }

    func timerRestart() {
        self.durations = 0
        self.timeString = "00:00"
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            self.durations += 1
            
            // 格式化字符串
            let min = self.durations >= 60 ? self.durations / 60 : 0
            let seconds = self.durations - min * 60
            
            
            let minString = min >= 10 ? "\(min)" : "0\(min)"
            let secondString = self.durations - min * 60 >= 10 ? "\(seconds)" : "0\(seconds)"
            self.timeString = minString + ":" + secondString
        })
    }

    /// 游戏持续时间
    private var durations = 0
    // MARK: -- Init
    @Published var isWin = false
       /// 当前游戏状态
    private var currentStatus: GameStatus = .during {
        didSet {
            switch currentStatus {
            case .win: isWin = true
            case .lose: isWin = false
            case .during: break
            }
        }
    }
    init() {
    }
    // 设置便利构造方法
    convenience init(size: Int = 5, lightSequence: [Int] = [Int]()) {
        self.init()
        var size = size
        if size > 8 {
            size = 8
        }
        if size < 4 {
            size = 4
        }
        self.size = size
        lights = Array(repeating: Array(repeating: Light(), count: size), count: size)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
               self.durations += 1
               let min = self.durations >= 60 ? self.durations / 60 : 0
               let seconds = self.durations - min * 60
               let minString = min >= 10 ? "\(min)" : "0\(min)"
               let secondString = self.durations - min * 60 >= 10 ? "\(seconds)" : "0\(seconds)"
               self.timeString = minString + ":" + secondString
           })
        start(lightSequence)
    }
    /// 游戏配置
    /// - Parameter lightSequence： 亮灯序列
    func start(_ lightSequence: [Int]) {
        currentStatus = .during
        clickTimes = 0
        updateLightStatus(lightSequence)
    }
    
    /// 通过亮灯序列修改灯状态
    /// - Parameter lightSequence: 亮灯序列
    private func updateLightStatus(_ lightSequence: [Int]) {
        guard let size = size else { return }
        
        for lightIndex in lightSequence {
            var row = lightIndex / size
            let column = lightIndex % size
            
            // column 不为 0，说明非最后一个
            // row 为 0，说明为第一行
            if column > 0 && row >= 0 {
                row += 1
            }
            updateLightStatus(column: column - 1, row: row - 1)
        }
        updateGameStatus()
        
    }
    
    /// 通过坐标索引修改灯状态
    /// - Parameters:
    ///   - column: 灯-列索引
    ///   - row: 灯-行索引
    func updateLightStatus(column: Int, row: Int) {
        lights[row][column].status.toggle()
        
        // 上
        let top = row - 1
        if !(top < 0) {
            lights[top][column].status.toggle()
        }
        // 下
        let bottom = row + 1
        if !(bottom > lights.count - 1) {
            lights[bottom][column].status.toggle()
        }
        // 左
        let left = column - 1
        if !(left < 0) {
            lights[row][left].status.toggle()
        }
        // 右
        let right = column + 1
        if !(right > lights.count - 1) {
            lights[row][right].status.toggle()
        }
        updateGameStatus()
    }
    
    func circleWidth() -> CGFloat {
        var circleWidth: CGFloat = 0.0
        if size == nil {
            return circleWidth
        }
        circleWidth = UIScreen.main.bounds.width / (CGFloat(size!) * 3.5)
        return circleWidth
    }
    /// 判赢
    private func updateGameStatus() {
        guard let size = size else { return }
        
        var lightingCount = 0
        
        
        for lightArr in lights {
            for light in lightArr {
                if light.status { lightingCount += 1 }
            }
        }
        
        if lightingCount == size * size {
            currentStatus = .lose
            timerStop()
            return
        }
        
        if lightingCount == 0 {
            currentStatus = .win
            timerStop()
            return
        }
    }
}


extension GameManager {
    enum GameStatus {
        /// 赢
        case win
        /// 输
        case lose
        /// 进行中
        case during
    }
}



public struct PlaygroundRootView: View {
    @ObservedObject var gameManager = GameManager()
    
    init() {
        gameManager = GameManager(size: 4, lightSequence: [1, 2, 3])
    }
    
    public var body: some View {
        VStack(alignment: .center) {
            HStack {
                Text("\(gameManager.timeString)")
                    .font(.system(size: 45))
                Spacer()
                Text("\(gameManager.clickTimes)步")
                    .font(.system(size: 45))
            }
                .padding(20)
            ForEach(0..<gameManager.lights.count) { row in
                    HStack(spacing: CGFloat(70/(self.gameManager.lights.count.self-1))) {
                        ForEach(0..<self.gameManager.lights[row].count) { column in
                            Circle()
                                .foregroundColor(self.gameManager.lights[row][column].status ? .yellow : .gray)
                                .opacity(self.gameManager.lights[row][column].status ? 0.8 : 0.5)
                                .frame(width: self.gameManager.circleWidth(),
                                       height: self.gameManager.circleWidth())
                                .shadow(color: .yellow, radius: self.gameManager.lights[row][column].status ? 10 : 0)
                                .onTapGesture {
                                    self.gameManager.clickTimes += 1
                                    self.gameManager.updateLightStatus(column: column, row: row)
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: CGFloat(70/(self.gameManager.lights.count.self-1)), trailing: 0))
                }
                .alert(isPresented: $gameManager.isWin) {
                    Alert(title: Text("黑灯瞎火，摸鱼成功！"),
                          dismissButton: .default(Text("继续摸鱼"),
                          action: {
                            self.gameManager.start([3, 2, 1])
                            
                            self.gameManager.timerRestart()
                          }
                        )
                    )
                }
            }
    }
}
    

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = UIHostingController(rootView: PlaygroundRootView())
