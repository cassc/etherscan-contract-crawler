// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {IPool} from "aave-v3/interfaces/IPool.sol";

import {Constants as C} from "../../lib/Constants.sol";
import {IMorpho} from "../../interfaces/morpho/IMorpho.sol";
import {IAdapter} from "../IAdapter.sol";

contract MorphoAaveV3ScWethAdapter is IAdapter {
    using SafeTransferLib for ERC20;

    IMorpho public constant morpho = IMorpho(C.MORPHO);

    uint256 public constant id = 4;

    function setApprovals() external override {
        ERC20(C.WSTETH).safeApprove(address(morpho), type(uint256).max);
        ERC20(C.WETH).safeApprove(address(morpho), type(uint256).max);
    }

    function revokeApprovals() external override {
        ERC20(C.WSTETH).safeApprove(address(morpho), 0);
        ERC20(C.WETH).safeApprove(address(morpho), 0);
    }

    function supply(uint256 _amount) external override {
        morpho.supplyCollateral(C.WSTETH, _amount, address(this));
    }

    function borrow(uint256 _amount) external override {
        morpho.borrow(C.WETH, _amount, address(this), address(this), 0);
    }

    function repay(uint256 _amount) external override {
        morpho.repay(C.WETH, _amount, address(this));
    }

    function withdraw(uint256 _amount) external override {
        morpho.withdrawCollateral(C.WSTETH, _amount, address(this), address(this));
    }

    function claimRewards(bytes calldata _data) external override {
        address[] memory assets = abi.decode(_data, (address[]));
        morpho.claimRewards(assets, address(this));
    }

    function getCollateral(address _account) external view override returns (uint256) {
        return morpho.collateralBalance(C.WSTETH, _account);
    }

    function getDebt(address _account) external view override returns (uint256) {
        return morpho.borrowBalance(C.WETH, _account);
    }

    function getMaxLtv() external view override returns (uint256) {
        // same as the maxLtv for aave v3 on eMode
        return uint256(IPool(C.AAVE_V3_POOL).getEModeCategoryData(C.AAVE_EMODE_ID).ltv) * 1e14;
    }
}