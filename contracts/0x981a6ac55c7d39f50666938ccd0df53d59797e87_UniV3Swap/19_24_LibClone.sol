// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title Modified minimal proxy
/// @author 0xSplits
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @dev Modified minimal proxy includes a `receive()` method that emits the
/// `ReceiveETH(uint256)` event to skip `DELEGATECALL` when there is no calldata.
/// Enables us to accept hard gas-capped `sends` & `transfers` for maximum backwards
/// composability.
library LibClone {
    error DeploymentFailed();

    uint256 private constant FREE_PTR = 0x40;
    uint256 private constant ZERO_PTR = 0x60;

    /// @dev Deploys a modified minimal proxy of `implementation`
    function clone(address implementation) internal returns (address instance) {
        assembly ("memory-safe") {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes - 0x09)                                                 |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 3d         | RETURNDATASIZE    | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (89 bytes - 0x59)                                                 |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * 36      | CALLDATASIZE   | cds                    |                       |
             * 60 0x2c | PUSH1 0x2c     | 0x2c cds               |                       |
             * 57      | JUMPI          |                        |                       |
             * 34      | CALLVALUE      | cv                     |                       |
             * 3d      | RETURNDATASIZE | 0 cv                   |                       |
             * 52      | MSTORE         |                        | [0..0x20): callvalue  |
             * 7f sig  | PUSH32 0x9e..  | sig                    | [0..0x20): callvalue  |
             * 59      | MSIZE          | 0x20 sig               | [0..0x20): callvalue  |
             * 3d      | RETURNDATASIZE | 0 0x20 sig             | [0..0x20): callvalue  |
             * a1      | LOG1           |                        | [0..0x20): callvalue  |
             * 00      | STOP           |                        | [0..0x20): callvalue  |
             * 5b      | JUMPDEST       |                        |                       |
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | 0                      |                       |
             * 3d      | RETURNDATASIZE | 0 0                    |                       |
             * 3d      | RETURNDATASIZE | 0 0 0                  |                       |
             * 3d      | RETURNDATASIZE | 0 0 0 0                |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            |                       |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          |                       |
             * 3d      | RETURNDATASIZE | 0 0 cds 0 0 0 0        |                       |
             * 37      | CALLDATACOPY   | 0 0 0 0                | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0 0 0     | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0 0 0 | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success 0 0            | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success 0 0        | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | rds rds success 0 0    | [0..cds): calldata    |
             * 93      | SWAP4          | 0 rds success 0 rds    | [0..cds): calldata    |
             * 80      | DUP1           | 0 0 rds success 0 rds  | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success 0 rds          | [0..rds): returndata  |
             *                                                                           |
             * 60 0x57 | PUSH1 0x57     | 0x57 success 0 rds     | [0..rds): returndata  |
             * 57      | JUMPI          | 0 rds                  | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             * TOTAL INIT (98 bytes - 0x62)                                                 |
             * --------------------------------------------------------------------------|
             */

            // save free pointer
            let fp := mload(FREE_PTR)

            mstore(0x51, 0x5af43d3d93803e605757fd5bf3) // 13 bytes
            mstore(0x44, implementation) // 20 bytes
            mstore(0x30, 0x593da1005b3d3d3d3d363d3d37363d73) // 16 bytes
            // `keccak256("ReceiveETH(uint256)")`
            mstore(0x20, 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff) // 32 bytes
            mstore(0x00, 0x60593d8160093d39f336602c57343d527f) // 17 bytes

            // total: 113 bytes = 0x71
            // offset: 15 bytes = 0x0f
            // data: 98 bytes = 0x62
            instance := create(0, 0x0f, 0x71)

            // restore free pointer, zero slot
            mstore(FREE_PTR, fp)
            mstore(ZERO_PTR, 0)

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }
}