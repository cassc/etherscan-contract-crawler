// SPDX-License-Identifier: GPL-3.0

// Amended by HashLips
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol";

contract ICGNUPAYMENTS is PaymentSplitter {
    
    constructor (address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable {}
    
}

/**
 ["0xAe598379f44D62a027018C37C78D61Ee576E0e50", 
 "0x418Fc56F4130C1d0Cc430d26227275a517561617"]
 */
 
 /**
 [90, 
 10]
 */