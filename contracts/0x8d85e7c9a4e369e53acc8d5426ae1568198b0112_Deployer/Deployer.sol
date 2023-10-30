/**
 *Submitted for verification at Etherscan.io on 2023-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Deployer {
    event Deployed(address addr, uint256 salt);

    function deploy(bytes memory code, uint256 salt) external  returns (address) {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
        return addr;
    }
}