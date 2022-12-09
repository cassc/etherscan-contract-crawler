// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../TokenTransfer.sol";

// Lock token before date
contract LockupEmitterDateAfter is TokenTransfer {
    uint256 public constant LOCKUP_EMITTER_DATE_AFTER = 1935663322; // May 4th 2100
    uint256 public constant LOCKUP_EMITTER_AMOUNT = 10000 * 1 ether; // Total amount of tokens the user has to hold

    // A reference to the emitter of the offer
    address internal aEmitter;

    /**
     * @dev
     */
    constructor(
        address _receiver,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _emitter
    ) public TokenTransfer(_receiver, _totalTokens, _tokenName, _tokenSymbol) {
        require(_emitter != address(0), "Emitter is empty");
        
        // save the address of the emitter
        aEmitter = _emitter;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check if were allowed to continue
        if (_msgSender() == aEmitter) {
            // rule only applies before
            if (block.timestamp < LOCKUP_EMITTER_DATE_AFTER) {
                // check if the balance is enough
                uint256 nBalance = balanceOf(aEmitter);

                // remove the transfer from the balance
                uint256 nFinalBalance = nBalance.sub(amount);

                // make sure the remaining tokens are more than the needed by the rule
                require(nFinalBalance >= LOCKUP_EMITTER_AMOUNT, "Transfering more than account allows");
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}