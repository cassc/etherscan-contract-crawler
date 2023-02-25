// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;
//import payment splitter

import "lib/openzeppelin-contracts/contracts/finance/PaymentSplitter.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TheConnorsPaymentSplitter is PaymentSplitter, Ownable {
    constructor (address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable {}
}