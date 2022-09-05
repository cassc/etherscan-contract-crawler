// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JupiterNFT.sol';

/**
 * @dev Defines a Jupiter Operator to be approved for all owner tokens.
 */
abstract contract JupiterApproved is JupiterNFT {
    function isApprovedForAll(address owner, address operator)
        override
        public
        virtual
        view
        returns (bool)
    {
        if (operators[operator]){
            return true;
        }
        return JupiterNFT.isApprovedForAll(owner, operator);
    }
}