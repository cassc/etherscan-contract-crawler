// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2022 0xPlasma Alliance
*/

/***
 *      ______             _______   __                                             
 *     /      \           |       \ |  \                                            
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______  
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \ 
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *                                                                                  
 *                                                                                  
 *                                                                                  
 */
 

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;


/// @dev Helpers for computing `FeeCollector` contract addresses.
library LibFeeCollector {

    /// @dev Compute the CREATE2 address for a fee collector.
    /// @param controller The address of the `FeeCollectorController` contract.
    /// @param initCodeHash The init code hash of the `FeeCollector` contract.
    /// @param poolId The fee collector's pool ID.
    function getFeeCollectorAddress(address controller, bytes32 initCodeHash, bytes32 poolId)
        internal
        pure
        returns (address payable feeCollectorAddress)
    {
        // Compute the CREATE2 address for the fee collector.
        return address(uint256(keccak256(abi.encodePacked(
            byte(0xff),
            controller,
            poolId, // pool ID is salt
            initCodeHash
        ))));
    }
}