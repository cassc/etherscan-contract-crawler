// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";

library AddressGenerator {

    bytes32 public constant DEPLOYMENT_SALT = keccak256("AnkrProtocol");

    function makeSureProtocolAddressDeterministic(address that, address sender) internal pure {
        address shouldBe = Create2Upgradeable.computeAddress(
            DEPLOYMENT_SALT,
            computeBytecodeHashEmptyConstructor(),
            sender
        );
        require(that == shouldBe, "AnkrProtocol: non-deterministic address");
    }

    function computeBytecodeHashEmptyConstructor() internal pure returns (bytes32 hash) {
        assembly {
            let length := codesize()
            let bytecode := mload(0x40)
            mstore(0x40, add(bytecode, and(add(add(length, 0x20), 0x1f), not(0x1f))))
            mstore(bytecode, length)
            codecopy(add(bytecode, 0x20), 0, length)
            hash := keccak256(bytecode, add(bytecode, length))
        }
    }

    function computeBytecodeHashWithConstructor() internal pure returns (bytes32 hash) {
        bytes memory bytecode;
        assembly {
            let length := codesize()
            bytecode := mload(0x40)
            mstore(0x40, add(bytecode, and(add(add(length, 0x20), 0x1f), not(0x1f))))
            mstore(bytecode, length)
            codecopy(add(bytecode, 0x20), 0, length)
        }
        uint256 ctor = 2;
        while (ctor < bytecode.length - 1 || bytecode[ctor + 0] != 0x60 || bytecode[ctor + 1] != 0x80) {
            ctor++;
        }
        require(ctor < bytecode.length - 1, "AnkrProtocol: ctor not found");
        assembly {
            let length := mload(bytecode)
            hash := keccak256(add(bytecode, ctor), add(bytecode, sub(length, ctor)))
        }
    }
}