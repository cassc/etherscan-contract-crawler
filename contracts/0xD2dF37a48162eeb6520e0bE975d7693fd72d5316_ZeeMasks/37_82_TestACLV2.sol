// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../acl/ACL.sol";

/// @notice mock ACL implementation for testing purposes
contract TestACLV2 is ACL {
    // solhint-disable-next-line comprehensive-interface
    function version() external pure returns (string memory) {
        return "V2";
    }
}