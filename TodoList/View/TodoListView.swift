//
//  TodoListView.swift
//  TodoList
//
//  Created by 尹毓康 on 2020/1/3.
//  Copyright © 2020 yukangyin. All rights reserved.
//

import SwiftUI
import Alamofire
import SwiftyJSON

struct TodoListView: View {
    // @Environment的作用是从环境中取出预定义的值
    // 从实体中获取数据的属性
    @Environment(\.managedObjectContext) var managedObjectContext
    // 依照dueDate的大小升序排列
    @FetchRequest(entity: TodoItem.entity(), sortDescriptors: [NSSortDescriptor(key: "dueDate", ascending: true)]) var todoItems: FetchedResults<TodoItem> // todoItems的类型是FetchedResults<TodoItem>
    @FetchRequest(entity: User.entity(), sortDescriptors: [NSSortDescriptor(key: "username", ascending: true)]) var users: FetchedResults<User>

    @State private var newToDoItemDetail = ""

    // 是否正在添加代办事项的标志，默认没有正在添加
    @State private var addingTodoItem = false

    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    VStack {
                        Text("Todo List")
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                        Text("\(todoItems.count) items")
                                .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        // 从远端同步数据
                        // 正在使用app的用户的email
                        var currentUserEmail = self.users[0].email
                        let parameters: Dictionary = ["email": currentUserEmail, ]
                        Alamofire.request("https://ruitsai.tech/records_init_sync_api/", method: .post, parameters: parameters)
                                .responseJSON { response in
                                    switch response.result.isSuccess {
                                    case true:
                                        if let value = response.result.value {

                                            let json = JSON(value)

                                            // 删除本地TodoItem数据库中的所有记录
                                            // 先清空本地数据
                                            for todoItem in self.todoItems {
                                                self.managedObjectContext.delete(todoItem)
                                                do {
                                                    try self.managedObjectContext.save()
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                            for (index, subJson): (String, JSON) in json {
                                                let detail = subJson["detail"].stringValue
                                                var Year = subJson["Year"].stringValue
                                                var Month = subJson["Month"].stringValue
                                                var Day = subJson["Day"].stringValue

                                                let timestamp = subJson["timestamp"].stringValue
                                                let newTodoItem = TodoItem(context: self.managedObjectContext)
                                                newTodoItem.detail = detail
                                                newTodoItem.dueDate = Date(year: Int(Year) ?? 2020, month: Int(Month) ?? 01, day: Int(Day) ?? 10)
                                                newTodoItem.checked = false
                                                newTodoItem.timeStamp = timestamp  // 20200108234117
                                                // 使用CoreData保存
                                                do {
                                                    try self.managedObjectContext.save()
                                                } catch {
                                                    print("***")
                                                    print(newTodoItem.detail)
                                                    print(newTodoItem.dueDate)
                                                    print(newTodoItem.checked)
                                                    print(error)
                                                }
                                            }

                                        } else {
                                            print("error happened")
                                        }
                                    case false:
                                        print(response.result.error)
                                    }
                                }

                    }) {
                        Image(systemName: "arrow.2.circlepath")
                    }
                    Spacer()
                }
                        .padding(.leading, 100)


                ScrollView {
                    ForEach(0..<todoItems.count, id: \.self) { index in
                        VStack {
                            // 显示周五、下周等信息
                            //更新提醒时间文本框
//                            let formatter = DateFormatter()
//                            //日期样式
//                            formatter.dateFormat = "yyyy年MM月dd日"
                            if index == 0 || self.dateFormatter.string(from: self.todoItems[index].dueDate) != self.dateFormatter.string(from: self.todoItems[index - 1].dueDate) {
                                HStack {
                                    Spacer().frame(width: 30)
                                    Text(date2Word(date: self.todoItems[index].dueDate))
                                    Spacer()
                                }
                            }
                            HStack {
                                Spacer().frame(width: 5)


                                // 仅显示每一条TodoItem的detail和dueDate，不显示是否被check
                                TodoItemView(checked: self.todoItems[index].checked, dueDate: self.todoItems[index].dueDate, detail: self.todoItems[index].detail, index: index)
                                Spacer().frame(width: 35)

                                // 显示是否被check的按钮,点击按钮即为check(删除该事项)
                                Button(action: {
                                    // 删除待办事项
                                    let todoItem = self.todoItems[index]

                                    let parameters: Dictionary = ["timestamp": todoItem.timeStamp,
                                                                  "email": self.users[0].email, ]
                                    Alamofire.request("https://ruitsai.tech/records_checked_api/", method: .post, parameters: parameters)
                                            .responseJSON { response in
                                                switch response.result.isSuccess {
                                                case true:
                                                    if let value = response.result.value {

                                                        let json = JSON(value)
                                                        let state = json[0]["state"].stringValue
                                                        if state == "sync success" {
                                                            // TODO: 跳出一个toast：thanks for register
                                                            print("sync ok")
                                                        } else if state == "repeat" {
                                                            // TODO: 跳出一个toast：ops,Email has been sign up
                                                            print(state)
                                                        } else {
                                                            print("error")
                                                        }

                                                    } else {
                                                        print("error happened")
                                                    }
                                                case false:
                                                    print(response.result.error)
                                                }
                                            }

                                    self.managedObjectContext.delete(todoItem)
                                    self.saveTodoItem()
                                }) {
                                    HStack {
                                        Spacer()
                                        VStack {
                                            Spacer().frame(width: 5)
                                            Image(systemName: "square")
                                                    .resizable()
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(Color.gray)
                                            Spacer().frame(width: 5)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                        .padding()
            }
            // 右下角的添加事项的加号
            Button(action: {
                // editingTodoItem取反
                self.addingTodoItem.toggle()
            }) {
                btnAdd()
            }.sheet(isPresented: $addingTodoItem) {
                AddTodoItemView()
                        .environment(\.managedObjectContext, (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
            }.offset(x: UIScreen.main.bounds.width / 2 - 70, y: UIScreen.main.bounds.height / 2 - 130).animation(.spring())
        }
                .padding(.top, 80)
                .padding(.bottom, 83)
    }

    func saveTodoItem() {
        do {
            try managedObjectContext.save()
        } catch {
            print(error)
        }
    }
}

struct btnAdd: View {
    var size: CGFloat = 65.0
    var body: some View {
        ZStack {
            Group {
                Circle()
                        .fill(Color("btnAdd-bg"))
            }.frame(width: self.size, height: self.size)
                    .shadow(color: Color("btnAdd-shadow"), radius: 10)
            Group {
                Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: size, height: size)
                        .foregroundColor(Color("theme"))
            }
        }
    }
}

struct TodoListView_Previews: PreviewProvider {
    static var previews: some View {
        TodoListView()
                .environment(\.managedObjectContext, (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)

    }
}
