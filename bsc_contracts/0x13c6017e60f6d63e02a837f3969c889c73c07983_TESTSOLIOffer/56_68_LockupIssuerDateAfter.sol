// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../TokenTransfer.sol";

/**
 * @dev LockupIssuerDateAfter locks a amount of tokens to the emitter until a specified date
 */
contract LockupIssuerDateAfter is TokenTransfer {
    uint256 public constant LOCKUP_ISSUER_DATE_AFTER = 2556198000; // Jan 1th 2050
    uint256 public constant LOCKUP_ISSUER_AMOUNT = 2000 * 1 ether; // Total amount of tokens the user has to hold

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
        require(_issuer != address(0), "Issuer is empty");

        bInitialized = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check if were allowed to continue
        if (_msgSender() == aIssuer && bInitialized) {
            // rule only applies before
            if (block.timestamp < LOCKUP_ISSUER_DATE_AFTER) {
                // check if the balance is enough
                uint256 nBalance = balanceOf(aIssuer);

                // remove the transfer from the balance
                uint256 nFinalBalance = nBalance.sub(amount);

                // make sure the remaining tokens are more than the needed by the rule
                require(
                    nFinalBalance >= LOCKUP_ISSUER_AMOUNT,
                    "Transfering more than account allows"
                );
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}