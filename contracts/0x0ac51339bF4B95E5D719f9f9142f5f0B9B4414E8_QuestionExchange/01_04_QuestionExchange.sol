// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";

/// @title QuestionExchange
/// @notice A contract allowing users to pay to have questions answered by other users
contract QuestionExchange is Owned, ReentrancyGuard {
    /// fee percentage up to 2 decimal places (1% = 100, 0.1% = 10, 0.01% = 1)
    uint8 public feePercentage;
    address public feeReceiver;

    enum QuestionStatus{ NONE, ASKED, ANSWERED, EXPIRED }

    struct Question {
        QuestionStatus status;
        string questionUrl;
        string answerUrl;
        address bidToken;
        uint256 bidAmount;
        uint256 expiresAt;
        address asker;
    }

    mapping(address => mapping(uint256 => Question)) public questions;
    mapping(address => uint256) public questionCounts;
    mapping(address => string) public profileUrls;

    mapping(address => uint256) public lockedAmounts;
    /// @notice emitted when a question is asked
    event Asked(
        address indexed answerer,
        address indexed asker,
        uint256 indexed questionId
    );

    /// @notice emitted when a question is answered
    event Answered(
        address indexed answerer,
        address indexed asker,
        uint256 indexed questionId
    );

    /// @notice emitted when a question is expired
    event Expired(
        address indexed answerer,
        address indexed asker,
        uint256 indexed questionId
    );

    /// @notice emitted when the fee receiver is set
    event FeeReceiverSet(
        address indexed feeReceiver
    );

    /// @notice emitted when the fee percentage is set
    event FeePercentageSet(
        uint8 indexed feePercentage
    );

    /// @notice emitted when the fee receiver is set
    event ProfileUrlSet(
        address indexed profileAddress,
        string indexed profileUrl
    );

    /// @notice thrown when providing an empty question
    error EmptyQuestion();

    /// @notice thrown when attempting to action a question with the wrong status
    error InvalidStatus();

    /// @notice thrown when attempting to expire a question is answered or not yet expired
    error NotExpired();

    /// @notice thrown when attempting to claim an expired question that is already claimed
    error ExpiryClaimed();

    /// @notice thrown when answering a question that is expired
    error QuestionExpired();

    /// @notice thrown when providing an empty answer
    error EmptyAnswer();

    /// @notice thrown when attempting to expire a question that sender did not ask
    error NotAsker();

    /// @notice thrown when attempting to send ETH to this contract via fallback method
    error FallbackNotPayable();
    
    /// @notice thrown when attempting to send ETH to this contract via receive method
    error ReceiveNotPayable();

    constructor(uint8 _feePercentage) Owned(msg.sender) {
        feePercentage = _feePercentage;
        feeReceiver = owner;

        emit FeePercentageSet(_feePercentage);
    }

    function ask(
        address answerer,
        address asker,
        string memory questionUrl,
        address bidToken,
        uint256 bidAmount,
        uint256 expiresAt
    ) public nonReentrant {
        uint256 nextQuestionId = questionCounts[answerer];
        questionCounts[answerer] = nextQuestionId + 1;

        questions[answerer][nextQuestionId] = Question({
            status: QuestionStatus.ASKED,
            questionUrl: questionUrl,
            bidToken: bidToken,
            bidAmount: bidAmount,
            expiresAt: expiresAt,
            asker: asker,
            answerUrl: ''
        });

        if(bidAmount != 0) {
            lockedAmounts[bidToken] += bidAmount;

            ERC20(bidToken).transferFrom(msg.sender, address(this), bidAmount);
        }

        emit Asked(answerer, asker, nextQuestionId);
    }

    function answer(
        uint256 questionId,
        string memory answerUrl
    ) public nonReentrant {
        Question storage question = questions[msg.sender][questionId];
        if(question.status != QuestionStatus.ASKED) revert InvalidStatus();
        if(question.expiresAt <= block.timestamp) revert QuestionExpired();

        question.answerUrl = answerUrl;
        question.status = QuestionStatus.ANSWERED;

        if(question.bidAmount != 0) {
            lockedAmounts[question.bidToken] -= question.bidAmount;
            uint256 feeAmount = feePercentage == 0 
                ? 0
                : question.bidAmount * feePercentage / 10000; // feePercentage is normalised to 2 decimals

            ERC20(question.bidToken).transfer(msg.sender, question.bidAmount - feeAmount);
            ERC20(question.bidToken).transfer(feeReceiver, feeAmount);
        }

        emit Answered(msg.sender, question.asker, questionId);
    }

    function expire(
        address answerer,
        uint256 questionId
    ) public nonReentrant {
        Question storage question = questions[answerer][questionId];
        if(question.status != QuestionStatus.ASKED) revert InvalidStatus();
        if(question.expiresAt > block.timestamp) revert NotExpired();
        if(question.asker != msg.sender) revert NotAsker();

        question.status = QuestionStatus.EXPIRED;
        
        if(question.bidAmount != 0) {
            lockedAmounts[question.bidToken] -= question.bidAmount;

            uint256 feeAmount = question.bidAmount * feePercentage / 10000; // feePercentage is normalised to 2 decimals
            ERC20(question.bidToken).transfer(question.asker, question.bidAmount - feeAmount);
            ERC20(question.bidToken).transfer(feeReceiver, feeAmount);
        }

        emit Expired(answerer, msg.sender, questionId);
    }

    function setFeePercentage(uint8 newFeePercentage) public onlyOwner {
        feePercentage = newFeePercentage;
        emit FeePercentageSet(newFeePercentage);
    }

    function setFeeReceiver(address newFeeReceiver) public onlyOwner {
        feeReceiver = newFeeReceiver;
        emit FeeReceiverSet(newFeeReceiver);
    }

    function setProfileUrl(string memory newProfileUrl) public {
        profileUrls[msg.sender] = newProfileUrl;
        emit ProfileUrlSet(msg.sender, newProfileUrl);
    }

    function rescueTokens(address tokenAddress) public {
        uint256 totalBalance = ERC20(tokenAddress).balanceOf(address(this));

        ERC20(tokenAddress).transfer(owner, totalBalance - lockedAmounts[tokenAddress]);
    }

    /// @notice prevents ETH being sent directly to this contract
    fallback() external {
        // ETH received with no msg.data
        revert FallbackNotPayable();
    }

    /// @notice prevents ETH being sent directly to this contract
    receive() external payable {
        // ETH received with msg.data that does not match any contract function
        revert ReceiveNotPayable();
    }
}