// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice Collision of indexer address and GraphcastID address. Require a different address than to the indexer (msg.sender).
/// @param _graphcastID Address to register as the Graphcast ID.
error InvalidGraphcastID(address _graphcastID);
/// @notice Occupied GraphcastID address - The address has already been registered.
/// @param _graphcastID Address to register as the Graphcast ID
error OccupiedGraphcastID(address _graphcastID);

/// @title A Registry for Graphcast IDs
/// @author GraphOps
/// @notice You can use this contract to register an address as a Graphcast ID for your Indexer Account.
/// Graphcast ID will allow you to operate Graphcast radios with a Graph Account identity.
/// @dev This contract utilizes Openzepplin Ownable and Transparent Upgradeable Proxy contracts
contract GraphcastRegistry is Initializable, OwnableUpgradeable {
    /// @notice Track mapping from indexer address to its registered GraphcastID address
    /// @dev Restricted to 1:1 mapping
    mapping(address => address) public graphcastIDAuthorized;
    
    /// @notice Track mapping of addresseas to registration status as a GraphcastID
    /// @dev Initially all false, update status within `setGraphcastID`
    mapping(address => bool) public graphcastIDRegistered;

    /**
     * @dev Emitted when `indexer` sets `graphcastID` access.
     */
    event SetGraphcastID(address indexed indexer, address indexed graphcastID);

    /**
     * @notice Function to register GraphcastID address
     * @dev Authorize an address to be a Graphcast ID. (unauthorize by setting address 0)
     * @param _graphcastID Address to authorize as the Graphcast ID
     */
    function setGraphcastID(address _graphcastID) external virtual {
        if (_graphcastID == msg.sender)
            revert InvalidGraphcastID(_graphcastID);
        if (_graphcastID != address(0) && graphcastIDRegistered[_graphcastID])
            revert OccupiedGraphcastID(_graphcastID);
        // unset previous graphcastID
        if (graphcastIDAuthorized[msg.sender] != address(0)){
            graphcastIDRegistered[graphcastIDAuthorized[msg.sender]] = false;
        }
        graphcastIDAuthorized[msg.sender] = _graphcastID;
        graphcastIDRegistered[_graphcastID] = true;
        emit SetGraphcastID(msg.sender, _graphcastID);
    }

    /**
     * @notice Initial contract deployment that sets the owner
     * @dev Default owner passed in is the deployer address
     */    
    function initialize() external initializer {
        __Ownable_init();
    }
}