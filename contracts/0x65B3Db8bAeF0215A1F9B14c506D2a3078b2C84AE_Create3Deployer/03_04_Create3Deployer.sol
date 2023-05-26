// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Create3.sol";

contract Create3Deployer is Ownable {
    function deploy(bytes32 salt, bytes calldata code) external onlyOwner returns (address) {
        return Create3.create3(salt, code);
    }

    function addressOf(bytes32 salt) external view returns (address) {
        return Create3.addressOf(salt);
    }
}