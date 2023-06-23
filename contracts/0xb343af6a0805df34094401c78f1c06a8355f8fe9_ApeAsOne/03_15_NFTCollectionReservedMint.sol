// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../NFTCollection.sol";

abstract contract NFTCollectionReservedMint is NFTCollection {
    uint256 public immutable reservedAmount;

    uint256 public reservedAmountLeft;

    error ReservedSupplyExceeded();

    constructor(uint256 _reservedAmount) {
        reservedAmount = _reservedAmount;
        reservedAmountLeft = _reservedAmount;
    }

    function _mintAmount(uint256 _amount) internal virtual override {
        if (_amount == 0) {
            revert MinimumOneNFT();
        }
        if (_amount > maxMintAmount) {
            revert MaxMintAmountExceeded();
        }
        if (_totalMinted() + _amount + reservedAmount > maxSupply) {
            revert MaxSupplyExceeded();
        }
        _safeMint(msg.sender, _amount);
    }

    function mintReserved(uint256 _amount) public onlyOwner {
        if (reservedAmountLeft < _amount) {
            revert ReservedSupplyExceeded();
        }
        reservedAmountLeft -= _amount;
        _safeMint(msg.sender, _amount);
    }
}