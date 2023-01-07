//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

abstract contract NieuxPaymentSplitter is PaymentSplitter, Ownable {

    address[] private payees;

    mapping(address => bool) private payeesMapping;
    
    constructor(
        address[] memory payees_,
        uint256[] memory shares
    ) PaymentSplitter(payees_, shares) {
        payees = payees_;
        for (uint256 i = 0; i < payees_.length; i++) {
            payeesMapping[payees_[i]] = true;
        }
    }

    /*******************
        withdraw/release payments
    */
    function releaseAll() 
        public 
        virtual 
    {
        require(payeesMapping[msg.sender] == true, "caller must be a payee");

        for (uint256 i = 0; i < payees.length; i++) {
            super.release(payable(payees[i]));
        }
    }

    function release(address payable account) 
        public 
        override 
    {
        require(payeesMapping[msg.sender] == true, "caller must be a payee");
        super.release(account);
    }

    function release(IERC20 token, address account) 
        public 
        override 
        onlyOwner 
    {
        super.release(token, account);
    }
}