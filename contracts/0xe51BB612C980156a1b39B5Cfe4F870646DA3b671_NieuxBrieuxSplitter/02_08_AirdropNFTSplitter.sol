//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

abstract contract AirdropNFTSplitter is PaymentSplitter, Ownable {

    address[] private payees;

    mapping(address => bool) private payeesMapping;

    constructor(
        address[] memory payees_,
        uint256[] memory shares
    ) PaymentSplitter(payees_, shares) 
    { 
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
        require(payeesMapping[msg.sender] == true || msg.sender == owner(), "caller must be a payee or owner");

        for (uint256 i = 0; i < payees.length; i++) {
            super.release(payable(payees[i]));
        }
    }

    function release(address payable account)
        public
        override
    {
        require(payeesMapping[msg.sender] == true || msg.sender == owner(), "caller must be a payee or owner");
        super.release(account);
    }

    function releaseAll(IERC20 token) 
        public
        virtual
    {
        require(payeesMapping[msg.sender] == true || msg.sender == owner(), "caller must be a payee or owner");

        for (uint256 i = 0; i < payees.length; i++) {
            super.release(token, payable(payees[i]));
        }
    }

    function release(IERC20 token, address account) 
        public
        override
    {
        require(payeesMapping[msg.sender] == true || msg.sender == owner(), "caller must be a payee or owner");
        super.release(token, account);
    }
}