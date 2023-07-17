// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../src/paymaster/Whitelist.sol";

contract $Whitelist is Whitelist {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_check(address _sponsor,address _account) external view returns (bool ret0) {
        (ret0) = super._check(_sponsor,_account);
    }

    function $_add(address _account) external {
        super._add(_account);
    }

    function $_addBatch(address[] calldata _accounts) external {
        super._addBatch(_accounts);
    }

    function $_remove(address _account) external {
        super._remove(_account);
    }

    function $_removeBatch(address[] calldata _accounts) external {
        super._removeBatch(_accounts);
    }

    function $_checkOwner() external view {
        super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}