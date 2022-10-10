// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

struct OwnersStorage {
    bool initialized;
    address[] owners;
    mapping(address => bool) isOwner;
}

library LibOwners {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.owners.storage");

    function facetStorage() internal pure returns (OwnersStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function initialize() internal {
        OwnersStorage storage s = facetStorage();
        require(!s.initialized, "Owners: already initialized");

        s.owners.push(msg.sender);
        s.isOwner[msg.sender] = true;
        s.initialized = true;
    }

    function enforceOnlySuperOwner() internal view {
        OwnersStorage storage s = facetStorage();
        require(s.owners[0] == msg.sender, "Owners: Only Super Owner");
    }

    function enforceOnlyOwners() internal view {
        OwnersStorage storage s = facetStorage();
        require(s.isOwner[msg.sender], "Owners: Only Owner");
    }

    function isOwner(address user) internal view returns (bool) {
        OwnersStorage storage s = facetStorage();
        return s.isOwner[user];
    }
}

abstract contract OwnersAware {
    modifier onlyOwners {
        LibOwners.enforceOnlyOwners();
        _;
    }
}

contract Handler_OwnersFacet {
    function addOwner(address _new, bool _change) external {
        LibOwners.enforceOnlySuperOwner();

        OwnersStorage storage s = LibOwners.facetStorage();

        s.isOwner[_new] = true;
        if (_change) {
            s.owners.push(s.owners[0]);
            s.owners[0] = _new;
        } else {
            s.owners.push(_new);
        }
    }

    function removeOwner(address _new) external {
        LibOwners.enforceOnlySuperOwner();

        OwnersStorage storage s = LibOwners.facetStorage();

        require(s.isOwner[_new], "Owners: Not owner");
        require(_new != s.owners[0], "Owners: Cannot remove super owner");
        for (uint256 i = 1; i < s.owners.length; i++) {
            if (s.owners[i] == _new) {
                s.owners[i] = s.owners[s.owners.length - 1];
                s.owners.pop();
                break;
            }
        }

        s.isOwner[_new] = false;
    }
}