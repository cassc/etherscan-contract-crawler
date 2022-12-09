// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../TokenTransfer.sol";

// Lock up before date
contract ExpirationDateBefore is TokenTransfer {
    uint256 public constant EXPIRATION_DATE_RELEASE = 1967286694;
    bool private bInitialized;

    /**
     * @dev
     */
    constructor(
        address _emitter,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_emitter, _totalTokens, _tokenName, _tokenSymbol) {
        bInitialized = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check if were allowed to continue
        if (bInitialized && block.timestamp < EXPIRATION_DATE_RELEASE) {
            revert("Date is before token release date");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}