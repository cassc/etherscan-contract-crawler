// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./GraphcastRegistry.sol";

/// @notice Message sender is not authorized to set GraphcastID to _indexer if it is not _indexer 
/// themselves or some operator of the indexer that's registered on the Staking contract
/// @param _indexer Address to register Graphcast ID for.
error UnauthorizedCaller(address _indexer);

/// @notice Function has been deprecated since original implementation
error DeprecatedFunction();

contract Staking {
    function isOperator(address _operator, address _indexer) external view returns (bool) {}
    function hasStake(address _indexer) external view returns (bool) {}
}

/// @title A Registry for Graphcast IDs
/// @author GraphOps
/// @notice You can use this contract to register an address as a Graphcast ID for your Indexer Account.
/// Graphcast ID will allow you to operate Graphcast radios with a Graph Account identity.
/// @dev This contract utilizes Openzepplin Ownable and Transparent Upgradeable Proxy contracts
contract GraphcastRegistryV2 is GraphcastRegistry{
    /// @notice Track the Service Registry address
    /// @dev Initially nothing, owner can update with SetStaking 
    address public stakingAddr;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Check if the caller is authorized (either a staked indexer or operator of an indexer)
     */
    function _isAuth(address _indexer) internal view returns (bool) {
        return (msg.sender == _indexer && staking().hasStake(_indexer)) || staking().isOperator(msg.sender, _indexer) == true;
    }

    /**
     * @dev Return Staking interface
     * @return Staking contract registered with Graph Proxy Controller
     */
    function staking() internal view returns (Staking) {
        return Staking(stakingAddr);
    }

    /**
     * @dev Emitted when owner changes the address of the staking contract.
     */
    event SetStaking(address indexed staking);

    function setStaking(address _addr) external virtual onlyOwner {
        stakingAddr = _addr;
        emit SetStaking(stakingAddr);
    }

    /**
     * @notice Function to register GraphcastID address for an indexer
     * @dev Authorize an address to be a Graphcast ID. (unauthorize by setting address 0).
     * Make sure the message sender is the provided indexer,
     * or the message sender is an operator of the provided indexer by calling the Service Registry
     * @param _indexer Indexer address to authorize Graphcast ID for
     * @param _graphcastID Address to authorize as the Graphcast ID
     */
    function setGraphcastIDFor(address _indexer, address _graphcastID) external virtual {
        if (!_isAuth(_indexer))
            revert UnauthorizedCaller(_indexer);
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
        emit SetGraphcastID(_indexer, _graphcastID);
    }

    /**
     * @notice Deprecated function to set GraphcastID address for an indexer
     * Use setGraphcastIDFor(address, address) instead
     */
    function setGraphcastID(address _graphcastID) external override {
        revert DeprecatedFunction();
    }
}