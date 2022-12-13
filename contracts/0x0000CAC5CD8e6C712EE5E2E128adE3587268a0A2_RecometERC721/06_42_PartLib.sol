// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BasisPointLib.sol";

library PartLib {
    bytes32 public constant TYPE_HASH =
        keccak256("PartData(address account,uint256 value)");

    struct PartData {
        address payable account;
        uint256 value;
    }

    function hash(PartData memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }

    function validate(PartData memory part)
        internal
        pure
        returns (bool, string memory)
    {
        if (part.account == address(0x0)) {
            return (false, "PartLib: account verification failed");
        }
        if (part.value == 0 || part.value > BasisPointLib._BPS_BASE) {
            return (false, "PartLib: value verification failed");
        }
        return (true, "");
    }
}