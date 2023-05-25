// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ITarget } from "../interfaces/ITarget.sol";

library Adapter {
    // Pool info
    function lockableToken(ITarget target, uint256 poolId) external view returns (IERC20) {
        (bool success, bytes memory result) = address(target).staticcall(abi.encodeWithSignature("lockableToken(uint256)", poolId));
        require(success, "lockableToken(uint256 poolId) staticcall failed.");
        return abi.decode(result, (IERC20));
    }

    function lockedAmount(ITarget target, uint256 poolId) external view returns (uint256) {
        // note the impersonation
        (bool success, bytes memory result) = address(target).staticcall(abi.encodeWithSignature("lockedAmount(address,uint256)", address(this), poolId));
        require(success, "lockedAmount(uint256 poolId) staticcall failed.");
        return abi.decode(result, (uint256));
    }

    // Pool actions
    function deposit(ITarget target, uint256 poolId, uint256 amount) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("deposit(address,uint256,uint256)", address(target), poolId, amount));
        require(success, "deposit(uint256 poolId, uint256 amount) delegatecall failed.");
    }

    function withdraw(ITarget target, uint256 poolId, uint256 amount) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("withdraw(address,uint256,uint256)", address(target), poolId, amount));
        require(success, "withdraw(uint256 poolId, uint256 amount) delegatecall failed.");
    }

    function claimReward(ITarget target, uint256 poolId) external {
        // note the impersonation
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("claimReward(address,address,uint256)", address(target), address(this), poolId));
        require(success, "claimReward(address, address user, uint256 poolId) delegatecall failed.");
    }

    function poolUpdate(ITarget target, uint256 poolId, uint256 amount) external {
        (bool success,) = address(target).delegatecall(abi.encodeWithSignature("poolUpdate(address,uint256,uint256)", address(target), poolId, amount));
        require(success, "poolUpdate(uint256 poolId, uint256 amount) delegatecall failed.");
    }

}