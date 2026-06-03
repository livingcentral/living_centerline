import UIKit
class OptionsTableViewCell: UITableViewCell {

    @IBOutlet var contentview: UIView!
    @IBOutlet var selectBtn: UIButton!
    @IBOutlet var OptionsLbl: UILabel!
    static let identifier = "OptionsTableViewCell"
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let screenHeight = UIScreen.main.bounds.height
        selectBtn.layer.cornerRadius = (screenHeight * 16 / 812) / 2
        selectBtn.layer.masksToBounds = true
        selectBtn.layer.borderWidth = 1
        selectBtn.layer.borderColor = UIColor(hex: "#D4D4D4").cgColor
        
        contentview.layer.cornerRadius = 16
        contentview.layer.borderColor = UIColor(hex: "#EEF0F2").cgColor
        contentview.layer.borderWidth = 1.2
    }
    
    @IBAction func selectbtn(_ sender: Any) {
//        updateUIForSelectedState(isSelected: true)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let margins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        contentView.frame = contentView.frame.inset(by: margins)
    }

    // New function to update UI based on selection
    func updateUIForSelectedState(isSelected: Bool) {
        if isSelected {
            // Update UI for selected state
            updateUiComponent(contentBorderColor: "#1782FF", selecteBtnBorderColor: "#1782FF", selectedBtnImage: "checkmark.circle.fill", selectedBtnTintColor: "#1782FF")
        } else {
            // Reset to default appearance
            updateUiComponent(contentBorderColor: "#EEF0F2", selecteBtnBorderColor: "#D4D4D4", selectedBtnImage: "circle", selectedBtnTintColor: "#D4D4D4")
        }
    }
    
    func updateUiComponent(contentBorderColor: String, selecteBtnBorderColor: String, selectedBtnImage: String, selectedBtnTintColor: String) {
        contentview.layer.borderColor = UIColor(hex: contentBorderColor).cgColor
        selectBtn.layer.borderColor = UIColor(hex: selecteBtnBorderColor).cgColor
        selectBtn.setImage(UIImage(systemName: selectedBtnImage), for: .normal)
        selectBtn.tintColor = UIColor(hex: selectedBtnTintColor)
    }
}

