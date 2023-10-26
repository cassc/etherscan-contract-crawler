// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/// @title Centaurify Royaltysplitter.
/// @author DaDogg80 - Viken Blockchain Solutions.
/// @notice This smart contract can be used as the royalty receiver account from secondary market sales of an NFT.
/// @dev This smart contract inherits the popular PaymentSplitter contract, developed by the OpenZeppelin team.


contract RoyaltySplitter is PaymentSplitter {

    constructor(address[] memory payees_, uint256[] memory shares_)  PaymentSplitter(payees_, shares_) {}

}