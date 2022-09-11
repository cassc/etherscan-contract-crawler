// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IRoyaltySplitter {
    function initialize(address[] calldata royaltyRecipients, uint256[] calldata _shares) external;
}