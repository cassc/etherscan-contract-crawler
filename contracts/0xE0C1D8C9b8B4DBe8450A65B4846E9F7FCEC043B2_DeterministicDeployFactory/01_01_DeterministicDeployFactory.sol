// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DeterministicDeployFactory {
    event Deployed(address deployAddress);
    function deployByCreate2(bytes memory bytecode, uint salt) external {
        address deployAddress;
        assembly {
            deployAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(deployAddress)) {
                revert(0, 0)
            }
        }
        emit Deployed(deployAddress);
    }
}