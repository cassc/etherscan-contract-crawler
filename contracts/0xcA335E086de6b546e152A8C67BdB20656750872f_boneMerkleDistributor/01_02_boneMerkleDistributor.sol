// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMerkleDistributor.sol";

contract boneMerkleDistributor is SafeMerkleDistributor {

    constructor(address token_, bytes32 merkleRoot_) SafeMerkleDistributor(token_, merkleRoot_) public {}
}