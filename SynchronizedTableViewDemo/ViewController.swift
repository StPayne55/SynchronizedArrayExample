//
//  ViewController.swift
//  SynchronizedTableViewDemo
//
//  Created by stephen payne on 10/4/22.
//

import UIKit

class ViewController: UITableViewController {
    var array = SynchronizedArray<Int>()
    var iterations = 100
    let group = DispatchGroup()
    var timer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(insertOrRemoveRow), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        for i in 0...iterations {
            array.append(i)
        }
        
        tableView.reloadData()
    }

    @objc func insertOrRemoveRow() {
        let randomRow = Int.random(in: 0..<array.count)
        let randomNum = arc4random()
        let isInsertion = (randomNum % 2 == 0)

        group.enter()

        if isInsertion {
            DispatchQueue.global().async {
                print("\nNEW THREAD:" + "\(Thread.current)")
                print("{")
                let sleepVal = arc4random() % UInt32(self.iterations / 4)
                usleep(sleepVal)
                print("     " + "Inserting item in array at index: \(randomRow)")
                self.array.insert(randomRow, at: randomRow)
                print("\n\n}\n")
                self.group.leave()
            }
        } else {
            DispatchQueue.global().async {
                print("\nNEW THREAD:" + "\(Thread.current)")
                print("{")
                let sleepVal = arc4random() % UInt32(self.iterations)
                usleep(sleepVal)
                print("     " + "Deleting item from array at index: \(randomRow)")
                self.array.remove(at: randomRow)
                print("\n\n}")
                self.group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if isInsertion {
                self.newItemsWereAdded(indices: [randomRow])
            } else {
                self.itemsWereDeleted(indices: [randomRow])
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard array.indices.contains(indexPath.row), let text = array[indexPath.row] else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = "ROW \(text)"
        return cell
    }
    
    
    /// New items come into the array on a background thread, then this is invoked from that thread
    private func newItemsWereAdded(indices: [Int]) {
        let indexPaths: [IndexPath] = indices.compactMap({ IndexPath(row: $0, section: 0) })
        DispatchQueue.main.async {
            print("     MAIN THREAD: Inserting row in tableview at index: \(indices)")
            self.tableView.insertRows(at: indexPaths, with: .left)
        }
    }
    
    /// Items are removed from the array on a background thread, then this is invoked from that thread
    private func itemsWereDeleted(indices: [Int]) {
        let indexPaths: [IndexPath] = indices.compactMap({ IndexPath(row: $0, section: 0) })
        DispatchQueue.main.async {
            print("     MAIN THREAD: Deleting row in tableview at index: \(indices)")
            self.tableView.deleteRows(at: indexPaths, with: .right)
        }
    }
}
