// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();

        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(canInitialize(), "Initializable: contract is already initialized");
        _setStoredVersion(revision);

        bool isTopLevelCall = !_initializing;

        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @notice Returns the revision number of the contract
     * @dev Needs to be defined in the inherited class as a constant.
     * @return The revision number
     **/
    function getRevision() public pure virtual returns (uint256);

    /**
     * @notice Returns true if and only if the function is running in the constructor
     * @return True if the function is running in the constructor
     **/
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    function canInitialize() public view returns (bool) {
        uint256 revision = getRevision();
        return !_initialized || isConstructor() || revision > _getStoredVersion();
    }

    function _getStoredVersion() internal view returns (uint256) {
        // keccak-256(eip1967.proxy.version)
        // = 0x460994c355dbc8229336897ed9def5884fb6b26b0a995b156780d056c758577e
        // bytes32 _slot = 0x460994c355dbc8229336897ed9def5884fb6b26b0a995b156780d056c758577d;
        return
            StorageSlot
                .getUint256Slot(0x460994c355dbc8229336897ed9def5884fb6b26b0a995b156780d056c758577d)
                .value;
    }

    function _setStoredVersion(uint256 val) internal {
        // keccak-256(eip1967.proxy.version) - 1
        // bytes32 _slot = 0x460994c355dbc8229336897ed9def5884fb6b26b0a995b156780d056c758577d;
        StorageSlot
            .getUint256Slot(0x460994c355dbc8229336897ed9def5884fb6b26b0a995b156780d056c758577d)
            .value = val;
    }
}