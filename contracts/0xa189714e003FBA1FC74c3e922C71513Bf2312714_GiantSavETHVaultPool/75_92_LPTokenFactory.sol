pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { ILPTokenInit } from "../interfaces/ILPTokenInit.sol";
import { UpgradeableBeacon } from "../proxy/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

/// @notice Contract for deploying a new LP token
contract LPTokenFactory {

    /// @notice Emitted when a new LP token instance is deployed
    event LPTokenDeployed(address indexed factoryCloneToken);

    /// @notice Address of LP token implementation that is cloned on each LP token
    address public lpTokenImplementation;

    /// @notice Address of the implementation beacon
    address public beacon;

    /// @param _lpTokenImplementation Address of LP token implementation that is cloned on each LP token deployment
    constructor(address _lpTokenImplementation, address _upgradeManager) {
        require(_lpTokenImplementation != address(0), "Address cannot be zero");

        lpTokenImplementation = _lpTokenImplementation;
        beacon = address(new UpgradeableBeacon(lpTokenImplementation, _upgradeManager));
    }

    /// @notice Deploys a new LP token
    /// @param _tokenSymbol Symbol of the LP token to be deployed
    /// @param _tokenName Name of the LP token to be deployed
    function deployLPToken(
        address _deployer,
        address _transferHookProcessor,
        string calldata _tokenSymbol,
        string calldata _tokenName
    ) external returns (address) {
        require(address(_deployer) != address(0), "Zero address");
        require(bytes(_tokenSymbol).length != 0, "Symbol cannot be zero");
        require(bytes(_tokenName).length != 0, "Name cannot be zero");

        address newInstance = address(new BeaconProxy(
                beacon,
                abi.encodeCall(
                    ILPTokenInit(payable(lpTokenImplementation)).init,
                    (
                        _deployer,
                        _transferHookProcessor,
                        _tokenSymbol,
                        _tokenName
                    )
                )
            ));

        emit LPTokenDeployed(newInstance);

        return newInstance;
    }
}