// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title VersionedInitializable
 * , inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract ParaVersionedInitializable {
    bytes32 constant VERSION_STORAGE_POSITION =
        bytes32(uint256(keccak256("paraspace.proxy.version.storage")) - 1);

    struct VersionStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint256 lastInitializedRevision;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool initializing;
    }

    function versionStorage()
        internal
        pure
        returns (VersionStorage storage vs)
    {
        bytes32 position = VERSION_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        VersionStorage storage vs = versionStorage();

        uint256 revision = getRevision();
        require(
            vs.initializing ||
                isConstructor() ||
                revision > vs.lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !vs.initializing;
        if (isTopLevelCall) {
            vs.initializing = true;
            vs.lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            vs.initializing = false;
        }
    }

    /**
     * @notice Returns the revision number of the contract
     * @dev Needs to be defined in the inherited class as a constant.
     * @return The revision number
     **/
    function getRevision() internal pure virtual returns (uint256);

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

    // Reserved storage space to allow for layout changes in the future.
    // uint256[50] private ______gap;
}