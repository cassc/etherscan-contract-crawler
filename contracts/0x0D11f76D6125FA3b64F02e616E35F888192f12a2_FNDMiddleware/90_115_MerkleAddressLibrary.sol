// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/MerkleAddressLibrary.sol";

contract $MerkleAddressLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $getMerkleRootForSender(bytes32[] calldata proof) external view returns (bytes32) {
        return MerkleAddressLibrary.getMerkleRootForSender(proof);
    }

    receive() external payable {}
}