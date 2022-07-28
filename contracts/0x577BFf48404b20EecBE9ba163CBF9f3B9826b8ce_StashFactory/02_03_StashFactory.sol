// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../utils/Interfaces.sol";

/// @title Stash Factory
contract StashFactory is IStashFactory {
    event ImpelemntationChanged(address _newImplementation);

    error Unauthorized();

    address public immutable operator;
    address public immutable rewardFactory;
    address public immutable proxyFactory;

    address public implementation;

    constructor(
        address _operator,
        address _rewardFactory,
        address _proxyFactory
    ) {
        operator = _operator;
        rewardFactory = _rewardFactory;
        proxyFactory = _proxyFactory;
    }

    /// @notice Used to set address for new implementation contract
    /// @param _newImplementation Address of new implementation contract
    function setImplementation(address _newImplementation) external {
        if (msg.sender != IController(operator).owner()) {
            revert Unauthorized();
        }
        implementation = _newImplementation;
        emit ImpelemntationChanged(_newImplementation);
    }

    /// @notice Create a stash contract for the given gauge
    /// @param _pid The PID of the pool
    /// @param _gauge Gauge address
    function createStash(uint256 _pid, address _gauge) external returns (address) {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        address stash = IProxyFactory(proxyFactory).clone(implementation);
        IStash(stash).initialize(_pid, msg.sender, _gauge, rewardFactory);
        return stash;
    }
}