// SPDX-License-Identifier: GPL-3.0-only
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol

pragma solidity ^0.8.16;

library BeaconClones {
    /**
     * @dev Deploys and returns the address of a clone that gets an implementation
     *      from the `beacon` and mimics its behaviour.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `beacon` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address beacon, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x6080604052348015600f57600080fd5b5060a88061001e6000396000f3fe6080)
            mstore(add(ptr, 0x20), 0x6040526040517f5c60da1b000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x40), 0x0000000000000081526000600160208260048573000000000000000000000000)
            mstore(add(ptr, 0x54), shl(0x60, beacon))
            mstore(add(ptr, 0x68), 0x5afa0360705780513682833781823684845af490503d82833e808015606c573d)
            mstore(add(ptr, 0x88), 0x83f35b3d83fd5b00fea264697066735822122002f8a2f5acabeb1d754972351e)
            mstore(add(ptr, 0xa8), 0xc784958a7f99e64f368c267a38bb375594c03c64736f6c634300081000330000)
            instance := create2(0, ptr, 0xc6, salt)
        }
        require(instance != address(0), "create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address beacon,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x6080604052348015600f57600080fd5b5060a88061001e6000396000f3fe6080)
            mstore(add(ptr, 0x20), 0x6040526040517f5c60da1b000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x40), 0x0000000000000081526000600160208260048573000000000000000000000000)
            mstore(add(ptr, 0x54), shl(0x60, beacon))
            mstore(add(ptr, 0x68), 0x5afa0360705780513682833781823684845af490503d82833e808015606c573d)
            mstore(add(ptr, 0x88), 0x83f35b3d83fd5b00fea264697066735822122002f8a2f5acabeb1d754972351e)
            mstore(add(ptr, 0xa8), 0xc784958a7f99e64f368c267a38bb375594c03c64736f6c63430008100033ff00)
            mstore(add(ptr, 0xc7), shl(0x60, deployer))
            mstore(add(ptr, 0xdb), salt)
            mstore(add(ptr, 0xfb), keccak256(ptr, 0xc6))
            predicted := keccak256(add(ptr, 0xc6), 0x55)
        }
    }
}