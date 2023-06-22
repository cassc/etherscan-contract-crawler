// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface  IWG0 {
    function depositKittiesAndMintTokens(uint256[] calldata _kittyIds) external;
    function burnTokensAndWithdrawKitties(uint256[] calldata _kittyIds, address[] calldata _destinationAddresses) external;
}