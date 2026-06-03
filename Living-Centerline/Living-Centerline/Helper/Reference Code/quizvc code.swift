//
//  quizvc code.swift
//  Living-Centerline
//
//  Created by Developer on 15/10/24.
//

//import Foundation
//extension QuizVC: UITableViewDelegate, UITableViewDataSource {
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return questionData[currentQuestionIndex].scaleDetails.options.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? OptionsTableViewCell else {
//            return UITableViewCell()
//        }
//        // Adjust option display based on whether the values start from 0
//       // let displayValue = isZeroBased ? option.value + 1 : option.value
//        let questionObject = questionData[indexPath.row]
//        cell.OptionsLbl.text = " \(indexPath.row + 1).   \(questionObject.text)"
//        // Check if the option is selected
//        let questionId = questionData[currentQuestionIndex]._id ?? ""
//        let answerValue = selectedOptions[questionId] ?? 500
//        print("index is \(indexPath.row) answer is \(answerValue - 1)")
//        let isSelected = indexPath.row == answerValue - 1 ? true : false
//        if isSelected {
//            cell.updateUIForSelectedState(isSelected: true)
//
//        } else {
//            cell.updateUIForSelectedState(isSelected: false)
//        }
////        if selectedOptions[questionId] == displayValue {
////            cell.updateUIForSelectedState(isSelected: true)
////        } else {
////            cell.updateUIForSelectedState(isSelected: false)
////        }
//        // Tag the button with the index of the option
//        cell.selectBtn.tag = indexPath.row
//        cell.selectBtn.addTarget(self, action: #selector(optionSelected(_:)), for: .touchUpInside)
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("index path \(indexPath.row)")
//
//        let selectedOption = OptionData[indexPath.row].value
//        // Adjust the value before storing based on whether it's zero-based
//        //let selectedValue = isZeroBased ? selectedOption.value + 1 : selectedOption.value
//        if selectedOption > 0 {
//            if let questionId = questionData[currentQuestionIndex]._id {
//                //selectedOptions[questionId] = selectedValue
//                selectedOptions[questionId] = selectedOption
//            }
//            saveSelectedOptions()
//           // loadOptions.removeAll()
//            //updateLoadOptions()
//            optionTableView.reloadData()
//        }
//    }
//
//    @objc func optionSelected(_ sender: UIButton) {
//        let selectedOptionIndex = sender.tag
//        let selectedOption = OptionData[selectedOptionIndex]
//        // Adjust the value before storing based on whether it's zero-based
//        let selectedValue = isZeroBased ? selectedOption.value + 1 : selectedOption.value
//
//        if let questionId = questionData[currentQuestionIndex]._id {
//            selectedOptions[questionId] = selectedValue
//        }
//        optionTableView.reloadData()
//    }
//}
