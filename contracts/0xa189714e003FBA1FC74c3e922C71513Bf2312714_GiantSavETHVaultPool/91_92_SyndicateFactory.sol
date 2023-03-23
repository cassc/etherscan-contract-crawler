pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { ISyndicateFactory } from "../interfaces/ISyndicateFactory.sol";
import { ISyndicateInit } from "../interfaces/ISyndicateInit.sol";
import { UpgradeableBeacon } from "../proxy/UpgradeableBeacon.sol";

/// @notice Contract for deploying a new KNOT syndicate
contract SyndicateFactory is ISyndicateFactory, Initializable {

    /// @notice Address of syndicate implementation that is cloned on each syndicate deployment
    address public syndicateImplementation;

    address public beacon;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _syndicateImpl Address of syndicate implementation that is cloned on each syndicate deployment
    function init(address _syndicateImpl, address _upgradeManager) external initializer {
        _init(_syndicateImpl, _upgradeManager);
    }

    function _init(address _syndicateImpl, address _upgradeManager) internal {
        syndicateImplementation = _syndicateImpl;
        beacon = address(new UpgradeableBeacon(syndicateImplementation, _upgradeManager));
    }

    /// @inheritdoc ISyndicateFactory
    function deploySyndicate(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] calldata _priorityStakers,
        bytes[] calldata _blsPubKeysForSyndicateKnots
    ) public override returns (address) {
        // Use CREATE2 to deploy the new instance of the syndicate
        bytes32 salt = calculateDeploymentSalt(msg.sender, _contractOwner, _blsPubKeysForSyndicateKnots.length);
        address newInstance = address(new BeaconProxy{salt: salt}(beacon, bytes("")));

        // Initialize the new syndicate instance with the params from the deployer
        ISyndicateInit(newInstance).initialize(
            _contractOwner,
            _priorityStakingEndBlock,
            _priorityStakers,
            _blsPubKeysForSyndicateKnots
        );

        // Off chain logging of all deployed instances from this factory
        emit SyndicateDeployed(newInstance);

        return newInstance;
    }

    /// @inheritdoc ISyndicateFactory
    function calculateSyndicateDeploymentAddress(
        address _deployer,
        address _contractOwner,
        uint256 _numberOfInitialKnots
    ) external override view returns (address) {
        bytes32 salt = calculateDeploymentSalt(_deployer, _contractOwner, _numberOfInitialKnots);
        return address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(abi.encodePacked(
                    type(BeaconProxy).creationCode,
                    abi.encode(beacon, bytes("")) // <-- abi.encode the parameters
                ))
            )))));
    }

    /// @inheritdoc ISyndicateFactory
    function calculateDeploymentSalt(
        address _deployer,
        address _contractOwner,
        uint256 _numberOfInitialKnots
    ) public override pure returns (bytes32) {
        return keccak256(abi.encode(_deployer, _contractOwner, _numberOfInitialKnots));
    }
}