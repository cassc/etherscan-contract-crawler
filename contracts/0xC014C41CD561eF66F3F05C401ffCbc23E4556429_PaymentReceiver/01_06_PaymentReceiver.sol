// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BaseContracts/Withdrawable.sol";
import "./PaymentReceiver.interface.sol";

contract PaymentReceiver is PaymentReceiverInterface, Withdrawable, Ownable {

    // ==== Variables ====

    bool public isPaymentEnabled = false;

    // ==== Events ====

    event Payment(uint amount, string paymentSessionid, address sender);

    // ==== Modifiers ====

    modifier onlyWhenPaymentEnabled() {
        require(isPaymentEnabled, "Payment is not enabled");
        _;
    }
    
    // ==== General Contract Admin ====

    function enablePayments() public override onlyOwner {
        isPaymentEnabled = true;
    }

    function disablePayments() public override onlyOwner {
        isPaymentEnabled = false;
    }

    // ==== Core Contract Functionality ====

    function pay(string calldata paymentSessionid) payable public override onlyWhenPaymentEnabled {
        emit Payment(msg.value, paymentSessionid, _msgSender());
    }

}