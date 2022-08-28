// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IPockies {
    event PricePerPockieUpdated(uint256 newPrice);
    event MaxPockiesPerWalletUpdated(uint256 newMaxPockiesPerWallet);
    event MaxPockiesPerTxUpdated(uint256 newMaxPockiesPerTx);
    event PresaleToggled();
    event RootHashUpdated(bytes32 newRootHash);
    event BaseUriUpdated(string newBaseUri);
    event HiddenUriUpdated(string newHiddenUri);
    event PockiesRevealed();
    event PockiesMinted(address receiver, uint256 mintAmount);
    event PresaleEndTimeUpdated();
}