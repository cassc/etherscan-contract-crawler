// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


abstract contract Reserved
{
    // Reserved
    uint256 public reservedMintSupply;
    uint256 public reservedMintQuantity;

    error ReservedMintedOut();
    error ReserveLimitExceeded();
    error ZeroReservedMintAddress();

    modifier checkReservedMintQuantity(uint256 _quantity) {
        if (reservedMintSupply == 0) revert ReservedMintedOut();
 
        // Checking if the required quantity of tokens still remains
        uint256 remainingSupply = reservedMintSupply - reservedMintQuantity;
        if (_quantity > remainingSupply) revert ReservedMintedOut();
        _;
    }

    modifier checkAddressReservedMint(address _to) {
        if (_to == address(0)){
            revert ZeroReservedMintAddress();
        }
        _;
    }

    function _setReservedMintSupply(uint256 _reservedMintSupply) internal {
        reservedMintQuantity = 0;
        reservedMintSupply = _reservedMintSupply;
    }
}