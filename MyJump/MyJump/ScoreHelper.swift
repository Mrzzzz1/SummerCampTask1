//
//  ScoreHelper.swift
//  MyJump
//
//  Created by Zjt on 2022/7/18.
//

import Foundation
import CoreData
import UIKit

class ScoreHelper: NSObject {
    
    private let kHeightScoreKey = "highest_score"
    
    private override init() {
        
    }

    static let shared: ScoreHelper = ScoreHelper()
    
    func getHighestScore() -> Int {
        return UserDefaults.standard.integer(forKey: kHeightScoreKey)
    }
    
    func setHighestScore(_ score: Int) {
        if score > getHighestScore() {
            UserDefaults.standard.set(score, forKey: kHeightScoreKey)
            UserDefaults.standard.synchronize()
        }
    }
    func saveScore(score:Int,time:String)
    {
        //获取管理的数据上下文 对象
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.persistentContainer.viewContext

        //创建对象
        let scoreInfo = NSEntityDescription.insertNewObject(forEntityName: "ScoreInfo",
                                                       into: context) as! ScoreInfo

        //对象赋值
        scoreInfo.score=Int32(score)
        scoreInfo.time=time
        
        //保存
        do {
            try context.save()
            print("保存成功！")
        } catch {
            fatalError("不能保存：\(error)")
        }
    }
    
    func queryScore()->[ScoreInfo]
    {
        //获取管理的数据上下文 对象
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.persistentContainer.viewContext

        //声明数据的请求
        let fetchRequest = NSFetchRequest<ScoreInfo>(entityName:"ScoreInfo")
        //查询操作
        do {
            var fetchedObjects = try context.fetch(fetchRequest)
            fetchedObjects.sort(by: { (s0,s1) in s0.score>s1.score})

//            //遍历查询的结果
//            for info in fetchedObjects{
//                print("score:\(info.score)")
//                print("time:\(info.time)")
//            }
            if fetchedObjects.count>200 {
                for i in 100..<fetchedObjects.count {
                    context.delete(fetchedObjects[i])
                }
                
            }
            if context.hasChanges {
                    try context.save()
                }
            return fetchedObjects

        }
        catch {
            fatalError("不能保存：\(error)")
        }
        
    }
    
//    func modifyScore()
//    {
//        //获取管理的数据上下文 对象
//        let app = UIApplication.shared.delegate as! AppDelegate
//        let context = app.persistentContainer.viewContext
//
//        //声明数据的请求
//        let fetchRequest = NSFetchRequest<ScoreInfo>(entityName:"ScoreInfo")
//
//        //设置查询条件
//        let predicate = NSPredicate(format: "id= '1' ", "")
//        fetchRequest.predicate = predicate
//
//        //查询操作
//        do {
//            let fetchedObjects = try context.fetch(fetchRequest)
//
//            //遍历查询的结果
//            for info in fetchedObjects{
//                //修改密码
//                info.password = "abcd"
//                //重新保存
//                try context.save()
//            }
//        }
//        catch {
//            fatalError("不能保存：\(error)")
//        }
//    }

    
}
