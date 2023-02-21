// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "../registry/MID.sol";
import "./IMIDRegistrarController.sol";
import "../resolvers/Resolver.sol";
import "./IBulkRenewal.sol";

contract BulkRenewal is IBulkRenewal {
    // namehash(.bnb)
    bytes32 constant private MID_NAMEHASH = 0xdba5666821b22671387fe7ea11d7cc41ede85a5aa67c3e7b3d68ce6a661f389c;
    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));

    MID public mid;
    IMIDRegistrarController controller;

    constructor(MID _mid, IMIDRegistrarController _controller) {
        require(address(_mid) != address(0) && address(_controller) != address(0), "invalid address");
        mid = _mid;
        controller = _controller;
    }

    function rentPrice(string[] calldata names, uint duration) external view override returns(uint total) {
        for(uint i = 0; i < names.length; i++) {
            total += controller.rentPrice(names[i], duration);
        }
    }

    function rentPrices(string[] calldata names, uint[] calldata durations) external view override returns(uint total) {
        for(uint i = 0; i < names.length; i++) {
            total += controller.rentPrice(names[i], durations[i]);
        }
    }

    function renewAll(string[] calldata names, uint duration) external payable override {
        for(uint i = 0; i < names.length; i++) {
            uint cost = controller.rentPrice(names[i], duration);
            controller.renew{value:cost}(names[i], duration);
        }
        // Send any excess funds back
        payable(msg.sender).transfer(address(this).balance);
    }

    // batch commit & register and helpers
    function makeBatchCommitmentWithConfig(string[] memory names, address owner, bytes32 secret, address resolver, address addr) view public override returns (bytes32[] memory results) {
        require(names.length > 0, "name count 0");
        results = new bytes32[](names.length);
        for (uint i = 0; i < names.length; ++i) {
            results[i] = controller.makeCommitmentWithConfig(names[i], owner, secret, resolver, addr);
        }
    }

    function batchCommit(bytes32[] memory commitments_) public override {
        require(commitments_.length > 0, "commitment count 0");
        for (uint i = 0; i < commitments_.length; ++i) {
            controller.commit(commitments_[i]);
        }
    }

    function batchRegisterWithConfig(string[] memory names, address owner, uint[] memory durations, bytes32 secret, address resolver, address addr) external payable override {
        require(names.length > 0, "name count 0");
        require(names.length == durations.length, "length mismatch");
        for (uint i = 0; i < names.length; ++i) {
            uint cost = controller.rentPrice(names[i], durations[i]);
            controller.registerWithConfig{value: cost}(names[i], owner, durations[i], secret, resolver, addr);
        }
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
         return interfaceID == INTERFACE_META_ID || interfaceID == type(IBulkRenewal).interfaceId;
    }
}