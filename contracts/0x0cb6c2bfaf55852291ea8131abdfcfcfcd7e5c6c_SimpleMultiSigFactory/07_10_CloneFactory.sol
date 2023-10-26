// SPDX-License-Identifier: MIT
// from https://github.com/optionality/clone-factory
pragma solidity 0.8.18;

// This contract is used to deploy minimal proxies (EIP1167) using the CREATE2 opcode
// Resources: https://eips.ethereum.org/EIPS/eip-1167
// https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract
// https://github.com/optionality/clone-factory
contract CloneFactory {
    function createClone(address target, bytes32 salt)
    internal
    returns (address payable result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            // load the next free memory slot as a place to store the clone contract data
            let clone := mload(0x40)

            // The bytecode block below is responsible for contract initialization
            // during deployment, it is worth noting the proxied contract constructor will not be called during
            // the cloning procedure and that is why an initialization function needs to be called after the
            // clone is created
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            // This stores the address location of the implementation contract
            // so that the proxy knows where to delegate call logic to
            mstore(add(clone, 0x14), targetBytes)

            // The bytecode block is the actual code that is deployed for each clone created.
            // It forwards all calls to the already deployed implementation via a delegatecall
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            // deploy the contract using the CREATE2 opcode
            // this deploys the minimal proxy defined above, which will proxy all
            // calls to use the logic defined in the implementation contract `target`
            result := create2(0, clone, 0x37, salt)
        }
    }

    function isClone(address target, address query)
    internal
    view
    returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            // load the next free memory slot as a place to store the comparison clone
            let clone := mload(0x40)

            // The next three lines store the expected bytecode for a miniml proxy
            // that targets `target` as its implementation contract
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            // the next two lines store the bytecode of the contract that we are checking in memory
            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)

            // Check if the expected bytecode equals the actual bytecode and return the result
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}