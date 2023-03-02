// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {CLendBase, IERC20, SafeERC20} from "CLendBase.sol";
import {IAaveLendingPool as ILendingPool} from "IAaveLendingPool.sol";
import {IAaveToken} from "IAaveToken.sol";

contract CLendAave is CLendBase {
    using SafeERC20 for IERC20;
    uint16 public constant REFERRAL_CODE = 0;

    function _getContractName() internal pure override returns (string memory) {
        return "CLendAave";
    }

    /**
        @notice Deposits `asset` from Invoker into LendingPool, where receiver receives the aToken
        @param lendingPool Address of `LendingPool`
        @param asset Underlying asset to be deposited
        @param amount Amount of asset to supply
        @param receiver Address that receives aToken
     */
    function supply(
        ILendingPool lendingPool,
        IERC20 asset,
        uint256 amount,
        address receiver
    ) external payable {
        _tokenApprove(asset, address(lendingPool), amount);
        lendingPool.deposit(address(asset), amount, receiver, REFERRAL_CODE);
    }

    /**
        @notice Withdraws supplied `asset` from LendingPool to the `receiver`. Invoker must have aToken
        @param lendingPool Address of `LendingPool`
        @param aToken aToken that is being withdrawn
        @param amount Amount of asset to withdraws
        @param receiver Address that receives underlying token
     */
    function withdraw(
        ILendingPool lendingPool,
        IAaveToken aToken,
        uint256 amount,
        address receiver
    ) external payable {
        address underlyingAsset = aToken.UNDERLYING_ASSET_ADDRESS();
        lendingPool.withdraw(underlyingAsset, amount, receiver);
    }

    /**
        @notice Withdraws all supplied `asset` from LendingPool to the `receiver`. Sender must have aToken
        @param lendingPool Address of `LendingPool`
        @param aToken aToken that is being withdrawn
        @param receiver Address that receives underlying token
     */
    function withdrawAllUser(
        ILendingPool lendingPool,
        IAaveToken aToken,
        address receiver
    ) external payable {
        address underlyingAsset = aToken.UNDERLYING_ASSET_ADDRESS();
        uint256 amount = aToken.balanceOf(msg.sender);
        IERC20(address(aToken)).safeTransferFrom(msg.sender, address(this), amount);
        lendingPool.withdraw(underlyingAsset, type(uint256).max, receiver);
    }

    /**
        @notice Borrows `asset` from LendingPool. Sender must first call `approveDelegation()`
        @param lendingPool Address of `LendingPool`
        @param asset Underlying asset to be borrowed
        @param amount Amount of asset to borrow
        @param interestRateMode 1 = STABLE. 2 = VARIABLE.
     */
    function borrow(
        ILendingPool lendingPool,
        IERC20 asset,
        uint256 amount,
        uint256 interestRateMode
    ) external payable {
        lendingPool.borrow(address(asset), amount, interestRateMode, REFERRAL_CODE, msg.sender);
    }

    /**
        @notice Repays `asset` to LendingPool. Invoker must have asset.
        @param lendingPool Address of `LendingPool`
        @param asset Underlying asset to be repayed
        @param amount Amount of asset to repay
        @param interestRateMode 1 = STABLE. 2 = VARIABLE.
     */
    function repay(
        ILendingPool lendingPool,
        IERC20 asset,
        uint256 amount,
        uint256 interestRateMode
    ) external payable {
        _tokenApprove(asset, address(lendingPool), amount);
        lendingPool.repay(address(asset), amount, interestRateMode, msg.sender);
    }
}