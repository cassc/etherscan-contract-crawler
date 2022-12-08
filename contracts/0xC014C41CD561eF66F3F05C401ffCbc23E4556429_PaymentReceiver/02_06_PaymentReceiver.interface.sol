// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./BaseContracts/Withdrawable.interface.sol";

abstract contract PaymentReceiverInterface is WithdrawableInterface {
    
    // ==== General Contract Admin ====

    function enablePayments() public virtual;

    function disablePayments() public virtual;


    // ==== Core Contract Functionality ====

    function pay(string calldata paymentSessionid) payable public virtual;
    
}