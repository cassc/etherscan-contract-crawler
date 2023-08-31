// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.21;

/**
 * @title RMRKCore
 * @author RMRK team
 * @notice Smart contract of the RMRK core module.
 * @dev This is currently just a passthrough contract which allows for granular editing of base-level ERC721 functions.
 */
contract RMRKCore {
    /**
     * @notice Version of the @rmrk-team/evm-contracts package
     * @return Version identifier of the smart contract
     */
    string public constant VERSION = "2.0.0";
    bytes4 public constant RMRK_INTERFACE = 0x524D524B; // "RMRK" in ASCII hex
}