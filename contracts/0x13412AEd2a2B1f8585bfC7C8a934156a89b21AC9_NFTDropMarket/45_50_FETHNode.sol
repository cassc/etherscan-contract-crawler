// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/mixins/shared/FETHNode.sol";

contract $FETHNode is FETHNode {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _feth) FETHNode(_feth) {}

    function $feth() external view returns (IFethMarket) {
        return feth;
    }

    function $_tryUseFETHBalance(uint256 totalAmount,bool shouldRefundSurplus) external {
        return super._tryUseFETHBalance(totalAmount,shouldRefundSurplus);
    }
}