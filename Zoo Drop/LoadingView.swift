import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            // You can set a background color or image here if you like.
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // The ProgressView automatically shows a spinning activity indicator.
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2.0) // Makes the spinner a bit larger.
                
                Text("Loading...")
                    .foregroundColor(.white)
                    .font(.title3)
            }
        }
    }
}

#Preview {
    LoadingView()
}
