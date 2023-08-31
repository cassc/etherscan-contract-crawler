// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./NPassCore.sol";
import "../interfaces/IN.sol";

/**
 * @title NPass contract
 * @author Tony Snark
 * @notice This contract provides basic functionalities to allow minting using the NPass
 * @dev This is hardcoded to the correct address of the n smart contract on the Ethereum mainnet
 *      This SHOULD be used for mainnet deployments
 */
abstract contract NPass is NPassCore {
    /**
     * @notice Construct an NPass instance
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param onlyNHolders True if only n tokens holders can mint this token
     */
    constructor(
        address _nContractAddress,
        string memory name,
        string memory symbol,
        bool onlyNHolders
    ) NPassCore(name, symbol, IN(_nContractAddress), onlyNHolders) {}
}