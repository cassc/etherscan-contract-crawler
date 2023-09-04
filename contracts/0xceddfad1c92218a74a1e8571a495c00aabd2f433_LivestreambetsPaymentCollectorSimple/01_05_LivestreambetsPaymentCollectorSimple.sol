// SPDX-License-Identifier: MIT

/*
  [Website]         https://www.livestreambets.gg
  [Twitter/X]       https://twitter.com/livestreambets
  [Telegram]        https://t.me/livestreambetsgg
*/

pragma solidity ^0.8.19;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LivestreambetsPaymentCollectorSimple is
    Ownable,
    Pausable,
    ReentrancyGuard
{
    address payable public payoutReceiver;

    event FundsReceived(address indexed sender, uint256 amount);
    event FundsReceivedForContestant(
        address indexed sender,
        uint256 indexed gameId,
        uint256 indexed contestantId,
        uint256 amount
    );

    error NotAllowed();
    error WithdrawFailed();
    error NoFundsSent();

    modifier onlyOwnerOrPayoutReceiver() {
        require(
            msg.sender == owner() || msg.sender == payoutReceiver,
            "Caller is neither the owner nor payout receiver"
        );
        _;
    }

    constructor(address payable payoutReceiver_) {
        payoutReceiver = payoutReceiver_;

        // Begin paused.
        _pause();
    }

    function setPayoutReceiver(
        address payable payoutReceiver_
    ) external onlyOwner {
        payoutReceiver = payoutReceiver_;
    }

    function withdraw() external onlyOwnerOrPayoutReceiver nonReentrant {
        (bool success, ) = payoutReceiver.call{value: address(this).balance}(
            ""
        );

        if (!success) {
            revert WithdrawFailed();
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function receivePaymentForContestant(
        uint256 gameId_,
        uint256 contestantId_
    ) external payable whenNotPaused {
        _processPayment();
        emit FundsReceivedForContestant(
            msg.sender,
            gameId_,
            contestantId_,
            msg.value
        );
    }

    function _processPayment() internal whenNotPaused {
        if (msg.value > 0) {
            emit FundsReceived(msg.sender, msg.value);
        } else {
            revert NoFundsSent();
        }
    }

    // Accept any incoming ETH.
    fallback() external payable {
        _processPayment();
    }

    // Accept any incoming ETH.
    receive() external payable {
        _processPayment();
    }
}