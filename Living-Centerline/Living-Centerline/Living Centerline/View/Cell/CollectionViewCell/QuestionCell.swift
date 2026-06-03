//
//  QuestionCell.swift
//  Living-Centerline
//
//  Created by Developer on 14/10/24.
//

import UIKit

var isUpdated = true
class QuestionCell: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource {
    // MARK: Outlet
    @IBOutlet weak var optionTableView: UITableView!
    @IBOutlet weak var questionNumberLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!

    // MARK: - PRoperties
    static let identifier = "QuestionCell"
    var questionData: GetQuestionData?
    var questionIndex = 0
    var answerValue = ""
//    var delegate: SendQuestionValueDelegate?
//    weak var viewController: QuizVC?
    var action: ((IndexPath) -> Void)? = nil
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialisation code
        optionTableView.register(UINib(nibName: OptionsTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: OptionsTableViewCell.identifier)
        optionTableView.delegate = self
        optionTableView.dataSource = self
        optionTableView.separatorStyle = .none

    }
    
    func setUpCollectionView(questionIndex: Int, questionData: GetQuestionData) {
        self.questionData = questionData
        //print("question index is \(questionIndex)")
        self.questionIndex = questionIndex
        guard let answerValue = questionData.selectedValue else { return }
        let value = getAnswerValue(from: questionData.scaleDetails.options, answerValue: answerValue)
        //print("value is \(value)")
     //   optionTableView.scrollToBottom(animated: true)
        if value == 100 {
           // print("value not found navigate to top")
            optionTableView.scrollToTop(totalOptions: questionData.scaleDetails.options.count, answerValue: value, animated: true)
        } else {
            if value > 4 {
                optionTableView.scrollToBottom(totalOptions: questionData.scaleDetails.options.count, answerValue: value, animated: true)
            } else {
                optionTableView.scrollToTop(totalOptions: questionData.scaleDetails.options.count, answerValue: value, animated: true)
            }
        }
        optionTableView.reloadData()
    }
    
    func getAnswerValue(from options: [Option], answerValue: String) -> Int {
        // Search for the option that matches the answerValue
        if let matchingOption = options.first(where: { $0.text == answerValue }) {
            // Return the integer value of the matching option
            return matchingOption.value
        }
        // Return nil if no matching option is found
        return 100
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let data = questionData?.scaleDetails.options.count else {
            return 0
        }
        return data
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = optionTableView.dequeueReusableCell(withIdentifier: OptionsTableViewCell.identifier, for: indexPath) as? OptionsTableViewCell,
              let questionObject = questionData else {
            return UITableViewCell()
        }
        let questionValue = questionObject.scaleDetails.options[indexPath.row].text
        guard let answerValue = questionObject.selectedValue else { return UITableViewCell() }
        //print("question value is \(questionValue) answer value is \(answerValue)")
        cell.OptionsLbl.text = questionValue
        let isSelected = questionValue == answerValue ? true : false
        cell.updateUIForSelectedState(isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        action?(indexPath)
    }
}

extension UITableView {

    // Scroll to the top row based on total options and answer value
    func scrollToTop(totalOptions: Int, answerValue: Int, animated: Bool) {
        DispatchQueue.main.async {
            let topIndexPath = IndexPath(row: 0, section: 0)
            if self.hasRowAtIndexPath(indexPath: topIndexPath) {
                self.scrollToRow(at: topIndexPath, at: .top, animated: animated)
            }
        }
    }

    // Scroll to the last row based on total options and answer value
    func scrollToBottom(totalOptions: Int, answerValue: Int, animated: Bool) {
        DispatchQueue.main.async {
            let lastSectionIndex = self.numberOfSections - 1
            let lastRowIndex = totalOptions - 1
            if lastRowIndex >= 0 {
                let bottomIndexPath = IndexPath(row: lastRowIndex, section: lastSectionIndex)
                if self.hasRowAtIndexPath(indexPath: bottomIndexPath) {
                    self.scrollToRow(at: bottomIndexPath, at: .bottom, animated: animated)
                }
            }
        }
    }
    // Helper function to check if a row exists at a given index path
    private func hasRowAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.section < self.numberOfSections && indexPath.row < self.numberOfRows(inSection: indexPath.section)
    }
}
