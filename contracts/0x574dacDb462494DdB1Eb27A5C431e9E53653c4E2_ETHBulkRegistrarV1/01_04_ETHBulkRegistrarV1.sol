// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "./IETHBulkRegistrar.sol";
import "./IETHRegistrarController.sol";
import "../bnbregistrar/IPriceOracle.sol";

contract ETHBulkRegistrarV1 is IETHBulkRegistrar {
    IETHRegistrarController public immutable registrarController;

    constructor(IETHRegistrarController _registrarController) {
        registrarController = _registrarController;
    }

    function bulkRentPrice(string[] calldata names, uint256 duration) external view override returns (uint256 total) {
        for (uint256 i = 0; i < names.length; i++) {
            uint price = registrarController.rentPrice(names[i], duration);
            total += price;
        }
        return total;
    }

    function bulkMakeCommitment(string[] calldata name, address owner, bytes32 secret) external view override returns (bytes32[] memory commitments) {
        commitments = new bytes32[](name.length);
        for (uint256 i = 0; i < name.length; i++) {
            commitments[i] = registrarController.makeCommitmentWithConfig(name[i], owner, secret, address(0), address(0));
        }
        return commitments;
    }

    function commitment(bytes32 commit) external view override returns (uint256) {
        return registrarController.commitments(commit);
    }

    function bulkCommit(bytes32[] calldata commitments) external override {
        for (uint256 i = 0; i < commitments.length; i++) {
            registrarController.commit(commitments[i]);
        }
    }

    function bulkRegister(string[] calldata names, address owner, uint duration, bytes32 secret) external override payable {
        uint256 cost = 0;
        for (uint256 i = 0; i < names.length; i++) {
            uint price = registrarController.rentPrice(names[i], duration);
            registrarController.register{value: (price)}(names[i], owner, duration, secret);
            cost = cost + price;
        }

        // Send any excess funds back
        payable(msg.sender).transfer(msg.value - cost);
    }
}