//
//  HomeView.swift
//  TodoList
//
//  Created by 尹毓康 on 2020/1/6.
//  Copyright © 2020 yukangyin. All rights reserved.
//

import SwiftUI
import Alamofire
import SwiftyJSON

//enum UserStatus {
//    case showingLoginView
//    case showingTodoListView
//}


struct HomeView: View {// 默认展示登陆界面

    // 获取所有的user
    @FetchRequest(entity: User.entity(), sortDescriptors: [NSSortDescriptor(key: "username", ascending: true)]) var users: FetchedResults<User>

    var body: some View {
        HStack {
            if self.users.count == 0 || self.users[0].auth == "unauthorized" {
                LoginView()
                        .animation(.easeInOut)
            } else if (self.users.count == 1 && self.users[0].auth == "authorized") {
                TodoListHomeView()
                        .animation(.easeInOut)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
