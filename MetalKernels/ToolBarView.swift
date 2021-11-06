//
//  ToolBarView.swift
//  FilterPediaiOS
//
//  Created by Владимир Костин on 23.09.2021.
//

import SwiftUI

struct ToolBarView: View {
    
    @Binding var showImporter: Bool
    
    var body: some View {
        ZStack(alignment: .bottom){
            Rectangle()
                .frame(width: UIScreen.sWidth, height: 64, alignment: .center)
                .foregroundColor(.white)
                .opacity(0.2)
            Button(action: {
                showImporter = true
            }, label: {
                Text("Add a photo\nfor processing")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.6))
                    .font(Font.system(size: 22, weight: .bold, design: .rounded))
            })
        }
    }
}
