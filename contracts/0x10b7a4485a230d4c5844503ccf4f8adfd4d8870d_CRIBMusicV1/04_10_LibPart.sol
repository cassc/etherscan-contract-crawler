// SPDX-License-Identifier: MIT
/*
 * LibPart.sol
 *
 * Author: Twinny
 * Reference: Jack Kasbeer (taken from 'dot')
 * Created: October 20, 2021
 */

pragma solidity >=0.5.16 <0.9.0;

//@dev We need this libary for Rarible
library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}