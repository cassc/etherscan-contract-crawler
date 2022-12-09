// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../TokenTransfer.sol";

// Lock token after date
contract ExpirationDateAfter is TokenTransfer {
    uint256 public constant EXPIRATION_DATE_AFTER = 1935663322;  // May 4th 2100 

    /**
     * @dev
     */
    constructor(
        address _emitter,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_emitter, _totalTokens, _tokenName, _tokenSymbol) {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check if were allowed to continue
        if (block.timestamp > EXPIRATION_DATE_AFTER) {
            revert("Date is after token lockup date");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}