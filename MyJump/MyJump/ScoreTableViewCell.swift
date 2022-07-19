//
//  ScoreTableViewCell.swift
//  MyJump
//
//  Created by Zjt on 2022/7/18.
//

import UIKit

class ScoreTableViewCell: UITableViewCell {
    var rankLabel: UILabel!
    var scoreLabel: UILabel!
    var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setUpView() {
        rankLabel = UILabel(frame: CGRect(x: 20, y: 10, width: 50, height: 50))
        rankLabel.font = UIFont.systemFont(ofSize: 20)
        scoreLabel = UILabel(frame: CGRect(x: 100, y: 10, width: 50, height: 50))
        scoreLabel.font = UIFont.systemFont(ofSize: 20)
        timeLabel = UILabel(frame: CGRect(x: 160, y: 10, width: 400, height: 50))
        timeLabel.font = UIFont.systemFont(ofSize: 20)
        contentView.addSubview(rankLabel)
        contentView.addSubview(scoreLabel)
        contentView.addSubview(timeLabel)
    }

    func fillView(rank: Int, score: Int, time: String) {
        rankLabel.text = "\(rank)"
        scoreLabel.text = "\(score)"
        timeLabel.text = time
    }
}
