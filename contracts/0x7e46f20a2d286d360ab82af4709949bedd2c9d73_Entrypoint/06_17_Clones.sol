// SPDX-License-Identifier: MIT
// NOTE: This was from the Immunefi Team.

pragma solidity ^0.8.19;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 *
 * Modified to implement the more-minimal variation described here https://medium.com/coinmonks/the-more-minimal-proxy-5756ae08ee48
 */

library Clones {
    error CreateFailed();
    error Create2Failed();

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602c80600a3d3981f33d3d3d3d363d3d37363d730000000000000000000000
            )
            mstore(add(ptr, 0x15), shl(0x60, implementation))
            mstore(
                add(ptr, 0x29),
                0x5af43d3d93803e602a57fd5bf300000000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x36)
        }
        if (instance == address(0)) {
            revert CreateFailed();
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(
        address implementation,
        bytes32 salt
    ) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602c80600a3d3981f33d3d3d3d363d3d37363d730000000000000000000000
            )
            mstore(add(ptr, 0x15), shl(0x60, implementation))
            mstore(
                add(ptr, 0x29),
                0x5af43d3d93803e602a57fd5bf300000000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x36, salt)
        }
        if (instance == address(0)) {
            revert Create2Failed();
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602c80600a3d3981f33d3d3d3d363d3d37363d730000000000000000000000
            )
            mstore(add(ptr, 0x15), shl(0x60, implementation))
            mstore(
                add(ptr, 0x29),
                0x5af43d3d93803e602a57fd5bf3ff000000000000000000000000000000000000
            )
            mstore(add(ptr, 0x37), shl(0x60, deployer))
            mstore(add(ptr, 0x4b), salt)
            mstore(add(ptr, 0x6b), keccak256(ptr, 0x36))
            predicted := keccak256(add(ptr, 0x36), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}