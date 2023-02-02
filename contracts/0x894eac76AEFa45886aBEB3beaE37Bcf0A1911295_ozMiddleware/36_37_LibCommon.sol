// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import { TradeOps } from '../arbitrum/AppStorage.sol';


/**
 * @notice Library of common methods using in both L1 and L2 contracts
 */
library LibCommon {

    /**
     * @notice L1 removal method
     * @dev Removes a token from the token database
     * @param tokensDB_ Array of addresses where the removal will occur
     * @param toRemove_ Token to remove
     */
    function remove(address[] storage tokensDB_, address toRemove_) internal {
        uint index;
        for (uint i=0; i < tokensDB_.length;) {
            if (tokensDB_[i] == toRemove_)  {
                index = i;
                break;
            }
            unchecked { ++i; }
        }
        for (uint i=index; i < tokensDB_.length - 1;){
            tokensDB_[i] = tokensDB_[i+1];
            unchecked { ++i; }
        }
        delete tokensDB_[tokensDB_.length-1];
        tokensDB_.pop();
    }

    /**
     * @notice Overloaded L2 removal method
     * @dev Removes a token and its swap config from the token database
     * @param swaps_ Array of structs where the removal will occur
     * @param swapToRemove_ Config struct to be removed
     */
    function remove(
        TradeOps[] storage swaps_, 
        TradeOps memory swapToRemove_
    ) internal {
        uint index;
        for (uint i=0; i < swaps_.length;) {
            if (swaps_[i].token == swapToRemove_.token)  {
                index = i;
                break;
            }
            unchecked { ++i; }
        }
        for (uint i=index; i < swaps_.length - 1;){
            swaps_[i] = swaps_[i+1];
            unchecked { ++i; }
        }
        delete swaps_[swaps_.length-1];
        swaps_.pop();
    }

    /**
     * @dev Extracts the details of an Account
     * @param data_ Bytes array containing the details
     * @return user Owner of the Account
     * @return token Token of the Account
     * @return slippage Slippage of the Account
     */
    function extract(bytes memory data_) internal pure returns(
        address user, 
        address token, 
        uint16 slippage
    ) {
        assembly {
            user := shr(96, mload(add(data_, 32)))
            token := shr(96, mload(add(data_, 52)))
            slippage := and(0xff, mload(add(mload(data_), data_)))
        }
    }
}