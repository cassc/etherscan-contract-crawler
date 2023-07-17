// SPDX-License-Identifier: MIT
/**
 _____
/  __ \
| /  \/ ___  _ ____   _____ _ __ __ _  ___ _ __   ___ ___
| |    / _ \| '_ \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
| \__/\ (_) | | | \ V /  __/ | | (_| |  __/ | | | (_|  __/
 \____/\___/|_| |_|\_/ \___|_|  \__, |\___|_| |_|\___\___|
                                 __/ |
                                |___/
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/ICvgControlTower.sol";

contract CvgQuest is Ownable2Step {
    struct Quest {
        uint256 rewardAmount;
        IERC20 rewardToken;
        bool solved;
        uint88 number;
        IERC721 rewardNft;
        uint256 rewardTokenId;
    }

    struct QuestView {
        Quest quest;
        bytes32 answer;
    }

    /// @dev quests data
    mapping(bytes32 => Quest) public quests; // answer => data

    /// @dev quests data for view
    QuestView[] public questData;

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            CONSTRUCTOR
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    constructor(address _treasuryDao, bytes32[] memory _answers, Quest[] memory _quests) {
        require(_answers.length == _quests.length, "DATA_LENGTH_MISMATCH");

        /// @dev save quests
        for (uint256 i; i < _answers.length;) {
            quests[_answers[i]] = _quests[i];
            questData.push(QuestView({ quest: _quests[i], answer: _answers[i] }));
            unchecked { ++i; }
        }

        /// @dev transfer ownership to treasury DAO
        _transferOwnership(_treasuryDao);
    }

    /**
     *  @notice Submits a quest answer and send rewards to user if answer is correct
     *  @param _stringAnswer user's answer
     */
    function submitAnswer(string memory _stringAnswer) external {
        bytes32 _answer = keccak256(abi.encodePacked(_stringAnswer));
        Quest memory _quest = quests[_answer];

        require(_quest.rewardAmount > 0 || _quest.rewardTokenId > 0, "INCORRECT_ANSWER");
        require(!_quest.solved, "QUEST_ALREADY_SOLVED");

        /// @dev set the quest as solved
        quests[_answer].solved = true;
        questData[quests[_answer].number].quest.solved = true;

        /// @dev send ERC20 tokens to user
        if (_quest.rewardAmount > 0) {
            _quest.rewardToken.transfer(msg.sender, _quest.rewardAmount);
        }

        /// @dev send ERC721 token to user
        if (_quest.rewardTokenId > 0) {
            _quest.rewardNft.transferFrom(address(this), msg.sender, _quest.rewardTokenId);
        }
    }

    /**
     *  @notice Add a new quest with its rewards
     *  @param _answer quest's correct answer
     *  @param _quest quest data
     */
    function addQuest(bytes32 _answer, Quest memory _quest) external onlyOwner {
        require(quests[_answer].rewardAmount == 0 && quests[_answer].rewardTokenId == 0, "QUEST_ALREADY_EXISTS");

        quests[_answer] = _quest;
        questData.push(QuestView({ quest: _quest, answer: _answer }));
    }

    /**
     *  @notice Remove a quest
     *  @param _answer quest's correct answer
     */
    function removeQuest(bytes32 _answer) external onlyOwner {
        if (quests[_answer].rewardAmount > 0) {
            quests[_answer].rewardToken.transfer(msg.sender, quests[_answer].rewardAmount);
        }

        if (quests[_answer].rewardTokenId > 0) {
            quests[_answer].rewardNft.transferFrom(address(this), msg.sender, quests[_answer].rewardTokenId);
        }

        delete questData[quests[_answer].number];
        delete quests[_answer];
    }

    function getQuestData() external view returns (QuestView[] memory) {
        return questData;
    }
}