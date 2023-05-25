// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "./IETHBulkRegistrar.sol";
import "./IETHRegistrarController.sol";

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

    function bulkMakeCommitment(string[] calldata name, address owner, bytes32 secret) external view override returns (bytes32[] memory commitmentList) {
        commitmentList = new bytes32[](name.length);
        for (uint256 i = 0; i < name.length; i++) {
            commitmentList[i] = registrarController.makeCommitmentWithConfig(name[i], owner, secret, address(0), address(0));
        }
        return commitmentList;
    }

    function commitments(bytes32 commit) external view override returns (uint256) {
        return registrarController.commitments(commit);
    }

    function bulkCommit(bytes32[] calldata commitmentList) external override {
        for (uint256 i = 0; i < commitmentList.length; i++) {
            registrarController.commit(commitmentList[i]);
        }
    }

    function bulkRegister(string[] calldata names, address owner, uint duration, bytes32 secret) external payable override {
        uint256 cost = 0;
        for (uint256 i = 0; i < names.length; i++) {
            uint price = registrarController.rentPrice(names[i], duration);
            registrarController.register{value: (price)}(names[i], owner, duration, secret);
            cost = cost + price;
        }

        // Send any excess funds back
        if (msg.value > cost) {
            (bool sent, ) = msg.sender.call{value: msg.value - cost}("");
            require(sent, "Failed to send Ether");
        }
    }

    function registerWithConfig(string calldata name, address owner, uint duration, bytes32 secret, address resolver, address addr) external payable override {
        uint cost = registrarController.rentPrice(name, duration);
        registrarController.registerWithConfig{value: cost}(name, owner, duration, secret, resolver, addr);
        // Send any excess funds back
        if (msg.value > cost) {
            (bool sent, ) = msg.sender.call{value: msg.value - cost}("");
            require(sent, "Failed to send Ether");
        }
    }

    function makeCommitmentWithConfig(string calldata name, address owner, bytes32 secret, address resolver, address addr) external view override returns (bytes32 commitment) {
        commitment = registrarController.makeCommitmentWithConfig(name, owner, secret, resolver, addr);
        return commitment;
    }
}