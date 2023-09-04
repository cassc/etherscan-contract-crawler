// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/interfaces/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.4/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenListPayment is Ownable {
    using SafeERC20 for IERC20;

    uint256 public paymentAmount;
    address public paymentReceiver;
    IERC20 public wsd;

    event PaymentAmountChanged(uint256 newAmount);
    event PaymentReceiverChanged(address newReceiver);
    event Payment(string id, address payer, address paymentReceiver, uint256 amount);

    constructor(address _wsd, address _paymentReceiver, uint256 _paymentAmount) {
        wsd = IERC20(_wsd);

        changePaymentReceiver(_paymentReceiver);
        changePaymentAmount(_paymentAmount);
    }

    function pay(string memory id) external {
        IERC20(wsd).safeTransferFrom(msg.sender, paymentReceiver, paymentAmount);

        emit Payment(id, msg.sender, paymentReceiver, paymentAmount);
    }

    function changePaymentAmount(uint256 _paymentAmount) public onlyOwner {
        require(_paymentAmount != 0, 'Can not be zero');
        paymentAmount = _paymentAmount;

        emit PaymentAmountChanged(_paymentAmount);
    }

    function changePaymentReceiver(address _paymentReceiver) public onlyOwner {
        require(_paymentReceiver != address(0), 'Can not be zero address');
        paymentReceiver = _paymentReceiver;
        emit PaymentReceiverChanged(_paymentReceiver);
    }
}