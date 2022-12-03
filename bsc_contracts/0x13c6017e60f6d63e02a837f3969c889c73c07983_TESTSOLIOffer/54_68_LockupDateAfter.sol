/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../TokenTransfer.sol";

/**
* @dev LockupDateAfter locks all token tranfers after a specified date
*/
contract LockupDateAfter is TokenTransfer {
    uint256 public constant LOCKUP_DATE_AFTER = 2556198000;  // May 4th 2100 

    /**
     * @dev
     */
    constructor(
        address _issuer,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_issuer, _totalTokens, _tokenName, _tokenSymbol) { }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check if were allowed to continue
        if (block.timestamp > LOCKUP_DATE_AFTER) {
            revert("Date is after token lockup date");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}