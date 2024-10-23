//
//  WeatherViews.swift
//  WeatherApp
//
//  Created by M W on 23/10/2024.
//
import SwiftUI


struct SunnyAnimationView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .cyan.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            
            Circle()
                .fill(Color.yellow)
                .frame(width: 120, height: 120)
                .blur(radius: isAnimating ? 20 : 40)
                .offset(y: -100)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear { isAnimating = true }
        }
    }
}

struct RainyAnimationView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray, .blue.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            
            ForEach(0..<50) { index in
                RainDropView()
                    .offset(x: CGFloat.random(in: -200...200))
            }
        }
    }
}

struct RainDropView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.blue.opacity(0.4))
            .frame(width: 4, height: 4)
            .offset(y: isAnimating ? 800 : -100)
            .animation(
                Animation.linear(duration: Double.random(in: 0.8...1.2))
                    .repeatForever(autoreverses: false)
                    .delay(Double.random(in: 0...2)),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

struct CloudyAnimationView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.7), .white.opacity(0.3)], startPoint: .top, endPoint: .bottom)
            
            // Multiple clouds at different positions
            ForEach(0..<4) { index in
                Cloud(offset: CGPoint(x: CGFloat(index) * 50 - 75, y: CGFloat(index) * 60 - 100))
                    .opacity(0.8)
            }
        }
    }
}

struct Cloud: View {
    let offset: CGPoint
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Base cloud shape
            CloudShape()
                .fill(Color.white.opacity(0.7))
                .frame(width: 180, height: 100)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                .offset(x: isAnimating ? 400 : -400, y: offset.y)
                .animation(
                    Animation.linear(duration: 20)
                        .repeatForever(autoreverses: false)
                        .delay(Double.random(in: 0...5)),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Calculate dimensions
        let width = rect.width
        let height = rect.height
        let baseHeight = height * 0.6
        
        // Draw the base of the cloud
        path.move(to: CGPoint(x: width * 0.2, y: baseHeight))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.8, y: baseHeight),
            control: CGPoint(x: width * 0.5, y: height)
        )
        
        // Add the top bubbles of the cloud
        // Left bubble
        path.addEllipse(in: CGRect(
            x: width * 0.15,
            y: height * 0.3,
            width: width * 0.25,
            height: height * 0.5
        ))
        
        // Middle-left bubble
        path.addEllipse(in: CGRect(
            x: width * 0.3,
            y: height * 0.2,
            width: width * 0.25,
            height: height * 0.5
        ))
        
        // Middle-right bubble
        path.addEllipse(in: CGRect(
            x: width * 0.45,
            y: height * 0.25,
            width: width * 0.25,
            height: height * 0.5
        ))
        
        // Right bubble
        path.addEllipse(in: CGRect(
            x: width * 0.6,
            y: height * 0.3,
            width: width * 0.25,
            height: height * 0.5
        ))
        
        return path
    }
}

struct ThunderstormAnimationView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            
            RainyAnimationView()
                .opacity(0.5)
            
            ForEach(0..<2) { _ in
                LightningBolt()
            }
        }
    }
}

struct LightningBolt: View {
    @State private var isAnimating = false
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 40))
            path.addLine(to: CGPoint(x: 0, y: 40))
            path.addLine(to: CGPoint(x: 30, y: 100))
        }
        .fill(Color.yellow)
        .frame(width: 30, height: 100)
        .offset(x: CGFloat.random(in: -100...100), y: -50)
        .opacity(isAnimating ? 0 : 1)
        .animation(
            Animation.easeOut(duration: 0.2)
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...3)),
            value: isAnimating
        )
        .onAppear { isAnimating = true }
    }
}

struct SnowyAnimationView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.3), .white], startPoint: .top, endPoint: .bottom)
            
            ForEach(0..<50) { _ in
                SnowflakeView()
            }
        }
    }
}

struct SnowflakeView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .offset(
                x: CGFloat.random(in: -200...200),
                y: isAnimating ? 800 : -100
            )
            .animation(
                Animation.linear(duration: Double.random(in: 5...7))
                    .repeatForever(autoreverses: false)
                    .delay(Double.random(in: 0...2)),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

struct FoggyAnimationView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.6), .white.opacity(0.3)], startPoint: .top, endPoint: .bottom)
            
            ForEach(0..<3) { index in
                FogLayer(offset: CGFloat(index) * 100)
            }
        }
    }
}

struct FogLayer: View {
    let offset: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.3))
            .frame(width: 200, height: 200)
            .blur(radius: 30)
            .offset(x: isAnimating ? 400 : -400, y: offset)
            .animation(
                Animation.linear(duration: 15)
                    .repeatForever(autoreverses: false)
                    .delay(Double.random(in: 0...5)),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

struct DefaultAnimationView: View {
    var body: some View {
        LinearGradient(
            colors: [.blue.opacity(0.6), .cyan.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

