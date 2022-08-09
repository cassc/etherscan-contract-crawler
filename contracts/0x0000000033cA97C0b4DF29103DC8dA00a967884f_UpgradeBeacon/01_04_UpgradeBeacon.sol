// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { TwoStepOwnable } from "../access/TwoStepOwnable.sol";

// prettier-ignore
import { 
    UpgradeBeaconInterface 
} from "../interfaces/UpgradeBeaconInterface.sol";

/**
 * @title   UpgradeBeacon
 * @author  OpenSea Protocol Team
 * @notice  UpgradeBeacon is a ownable contract that is used as a beacon for a
 *          proxy, to retreive it's implementation.
 *
 */
contract UpgradeBeacon is TwoStepOwnable, UpgradeBeaconInterface {
    address private _implementation;

    /**
     * @notice Sets the owner of the beacon as the msg.sender.  Requires
     *         the caller to be an approved deployer.
     *
  
     */
    constructor() {
        // Ensure the origin is an approved deployer.
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)),
            "Deployment must originate from an approved deployer."
        );
    }

    /**
     * @notice Upgrades the beacon to a new implementation. Requires
     *         the caller must be the owner, and the new implementation
     *         must be a contract.
     *
     * @param newImplementationAddress The address to be set as the new
     *                                 implementation contract.
     */
    function upgradeTo(address newImplementationAddress)
        external
        override
        onlyOwner
    {
        _setImplementation(newImplementationAddress);
        emit Upgraded(newImplementationAddress);
    }

    function initialize(address owner_, address implementation_) external {
        // Ensure the origin is an approved deployer.
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)) &&
                _implementation == address(0),
            "Initialize must originate from an approved deployer, and the implementation must not be set."
        );

        // Call initialize.
        _initialize(owner_, implementation_);
    }

    function _initialize(address owner_, address implementation_) internal {
        // Set the Initial Owner
        _setInitialOwner(owner_);

        // Set the Implementation
        _setImplementation(implementation_);

        // Emit the Event
        emit Upgraded(implementation_);
    }

    /**
     * @notice This function returns the address to the implentation contract.
     */
    function implementation() external view override returns (address) {
        return _implementation;
    }

    /**
     * @notice Sets the implementation contract address for this beacon.
     *         Requires the address to be a contract.
     *
     * @param newImplementationAddress The address to be set as the new
     *                                 implementation contract.
     */
    function _setImplementation(address newImplementationAddress) internal {
        if (address(newImplementationAddress).code.length == 0) {
            revert InvalidImplementation(newImplementationAddress);
        }
        _implementation = newImplementationAddress;
    }
}