/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../silica/ISilicaV2_1.sol";

/**
 * @title  Silica Factory Events Interface
 * @author Alkimiya team
 * @notice Contains all events emitted by a Silica contract
 */
interface ISilicaFactoryEvents {
    /// @notice The event emited when a new Silica contract is created.
    event NewSilicaContract(address newContractAddress, ISilicaV2_1.InitializeData initializeData, uint16 commodityType);
}