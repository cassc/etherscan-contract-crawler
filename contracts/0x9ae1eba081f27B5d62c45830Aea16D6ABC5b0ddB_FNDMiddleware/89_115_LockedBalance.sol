// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/LockedBalance.sol";

contract $LockedBalance {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    mapping(uint256 => LockedBalance.Lockups) internal $v_LockedBalance_Lockups;

    constructor() {}

    function $del(uint256 lockups,uint256 index) external payable {
        return LockedBalance.del($v_LockedBalance_Lockups[lockups],index);
    }

    function $set(uint256 lockups,uint256 index,uint256 expiration,uint256 totalAmount) external payable {
        return LockedBalance.set($v_LockedBalance_Lockups[lockups],index,expiration,totalAmount);
    }

    function $setTotalAmount(uint256 lockups,uint256 index,uint256 totalAmount) external payable {
        return LockedBalance.setTotalAmount($v_LockedBalance_Lockups[lockups],index,totalAmount);
    }

    function $get(uint256 lockups,uint256 index) external view returns (LockedBalance.Lockup memory) {
        return LockedBalance.get($v_LockedBalance_Lockups[lockups],index);
    }

    receive() external payable {}
}