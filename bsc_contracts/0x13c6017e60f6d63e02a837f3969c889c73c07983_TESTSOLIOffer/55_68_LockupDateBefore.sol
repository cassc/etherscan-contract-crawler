/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../TokenTransfer.sol";

/**
* @dev LockupDateBefore locks all token tranfers before a specified date
*/
contract LockupDateBefore is TokenTransfer {
    uint256 public constant LOCKUP_DATE_RELEASE = 2524662000;
    bool private bInitialized;

    /**
     * @dev
     */
    constructor(
        address _issuer,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_issuer, _totalTokens, _tokenName, _tokenSymbol) {
        bInitialized = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check if were allowed to continue
        if (bInitialized && block.timestamp < LOCKUP_DATE_RELEASE) {
            revert("Date is before token release date");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}