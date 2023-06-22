// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error FailedToFetchFacet();

// minimal inline subset of the full DiamondCloneLib to reduce deployment gas costs
library DiamondCloneMinimalLib {
    bytes32 constant DIAMOND_CLONE_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.clone.storage");
    bytes32 constant ACCESS_CONTROL_STORAGE_POSITION =
        keccak256("Access.Control.library.storage");

    struct DiamondCloneStorage {
        // address of the diamond saw contract
        address diamondSawAddress;
        // mapping to all the facets this diamond implements.
        mapping(address => bool) facetAddresses;
        // gas cache
        mapping(bytes4 => address) selectorGasCache;
    }

    struct AccessControlStorage {
        address _owner;
    }

    function diamondCloneStorage()
        internal
        pure
        returns (DiamondCloneStorage storage s)
    {
        bytes32 position = DIAMOND_CLONE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // calls externally to the saw to find the appropriate facet to delegate to
    function _getFacetAddressForCall() internal view returns (address addr) {
        DiamondCloneStorage storage s = diamondCloneStorage();

        addr = s.selectorGasCache[msg.sig];
        if (addr != address(0)) {
            return addr;
        }

        (bool success, bytes memory res) = s.diamondSawAddress.staticcall(
            abi.encodeWithSelector(0x14bc7560, msg.sig) // facetAddressForSelector
        );

        if (!success) revert FailedToFetchFacet();

        assembly {
            addr := mload(add(res, 32))
        }

        return s.facetAddresses[addr] ? addr : address(0);
    }

    function accessControlStorage()
        internal
        pure
        returns (AccessControlStorage storage s)
    {
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}