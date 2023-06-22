// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../silica/ISilicaV2_1.sol";

/**
 * @title Events emitted by the contract
 * @author Alkimiya team
 * @notice Contains all events emitted by a Silica contract
 */
interface ISilicaFactoryEvents {
    /// @notice The event emited when a new Silica contract is created.
    event NewSilicaContract(address newContractAddress, ISilicaV2_1.InitializeData initializeData, uint16 commodityType);
}