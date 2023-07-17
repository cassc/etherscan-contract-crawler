// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../../proxy/interface/IContractAllowListProxy.sol";

library RestrictApproveStorage {

    struct Layout {
        // CAL Proxy address
        IContractAllowListProxy CAL;
        // stores local allowed addresses
        EnumerableSet.AddressSet localAllowedAddresses;
        // flag of restriction by CAL
        bool restrictEnabled;// = true;
        // stores CAL restriction level
        uint256 CALLevel;// = 1;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('RestrictApprove.contracts.storage.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}