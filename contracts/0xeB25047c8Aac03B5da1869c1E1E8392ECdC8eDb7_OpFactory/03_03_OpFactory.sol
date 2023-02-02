// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";

import {IDefiOp} from "./interfaces/IDefiOp.sol";

contract OpFactory {
    address public immutable opImplementation;
    event OpCreated(address owner, address opContract);

    constructor(address opImplementation_) {
        opImplementation = opImplementation_;
    }

    function getOpFor(address wallet) external view returns (address op) {
        op = Clones.predictDeterministicAddress(
            opImplementation,
            keccak256(abi.encodePacked(wallet)),
            address(this)
        );
    }

    function createOp() external {
        createOpFor(msg.sender);
    }

    function createOpFor(address owner) public {
        address op = Clones.cloneDeterministic(
            opImplementation,
            keccak256(abi.encodePacked(owner))
        );
        IDefiOp(op).init(owner);

        emit OpCreated(owner, op);
    }
}