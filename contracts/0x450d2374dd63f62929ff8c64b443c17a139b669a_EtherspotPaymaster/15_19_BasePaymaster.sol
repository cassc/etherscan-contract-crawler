// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../src/paymaster/BasePaymaster.sol";

abstract contract $BasePaymaster is BasePaymaster {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(IEntryPoint _entryPoint) BasePaymaster(_entryPoint) {}

    function $_postOp(IPaymaster.PostOpMode mode,bytes calldata context,uint256 actualGasCost) external {
        super._postOp(mode,context,actualGasCost);
    }

    function $_requireFromEntryPoint() external {
        super._requireFromEntryPoint();
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