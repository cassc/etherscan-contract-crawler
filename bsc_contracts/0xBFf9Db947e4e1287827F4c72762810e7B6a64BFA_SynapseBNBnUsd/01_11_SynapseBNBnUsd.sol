// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Defii} from "../Defii.sol";
import {DefiiWithCustomExit} from "../DefiiWithCustomExit.sol";

contract SynapseBNBnUsd is Defii, DefiiWithCustomExit {
    IERC20 constant USDC = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
    IERC20 constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 constant USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);

    IERC20 constant nUSDLP = IERC20(0xa4b7Bc06EC817785170C2DbC1dD3ff86CDcdcc4C);
    IERC20 constant SYN = IERC20(0xa4080f1778e69467E905B8d6F72f6e441f9e9484);

    ISwapFlashLoan constant swapFlashLoan =
        ISwapFlashLoan(0x28ec0B36F0819ecB5005cAB836F4ED5a2eCa4D13);
    IMiniChefV2 constant miniChef =
        IMiniChefV2(0x8F5BBB2BB8c2Ee94639E55d5F41de9b4839C1280);
    uint256 constant pid = 1;

    function hasAllocation() public view override returns (bool) {
        return miniChef.userInfo(pid, address(this)).amount > 0;
    }

    function _enter() internal override {
        uint256 usdcBalance = USDC.balanceOf(address(this));
        USDC.approve(address(swapFlashLoan), usdcBalance);

        uint256[] memory amounts = new uint256[](4);
        amounts[2] = usdcBalance;
        uint256 nUSDLPAmount = swapFlashLoan.addLiquidity(
            amounts,
            0,
            block.timestamp
        );

        nUSDLP.approve(address(miniChef), nUSDLPAmount);
        miniChef.deposit(pid, nUSDLPAmount, address(this));
    }

    function exitParams(uint256 slippage) public view returns (bytes memory) {
        require(slippage >= 800, "Slippage must be >800, (>80%)");
        require(slippage <= 1200, "Slippage must be <1200, (<120%)");

        uint256 busdPerLp = swapFlashLoan.calculateRemoveLiquidityOneToken(
            1e18,
            1
        );
        uint256 usdcPerLp = swapFlashLoan.calculateRemoveLiquidityOneToken(
            1e18,
            2
        );
        uint256 usdtPerLp = swapFlashLoan.calculateRemoveLiquidityOneToken(
            1e18,
            3
        );

        uint8 returnTokenIndex;
        uint256 tokenAmounts;

        if (busdPerLp > usdcPerLp) {
            if (busdPerLp > usdtPerLp) {
                returnTokenIndex = 1;
                tokenAmounts = busdPerLp;
            } else {
                returnTokenIndex = 3;
                tokenAmounts = usdcPerLp;
            }
        } else {
            if (usdcPerLp > usdtPerLp) {
                returnTokenIndex = 2;
                tokenAmounts = usdcPerLp;
            } else {
                returnTokenIndex = 3;
                tokenAmounts = usdtPerLp;
            }
        }

        return abi.encode(returnTokenIndex, ((tokenAmounts * slippage) / 1000));
    }

    function _exitWithParams(bytes memory params) internal override {
        (uint8 tokenIndex, uint256 tokenPerLp) = abi.decode(
            params,
            (uint8, uint256)
        );
        IMiniChefV2.UserInfo memory balanceInfo = miniChef.userInfo(
            pid,
            address(this)
        );

        miniChef.withdrawAndHarvest(pid, balanceInfo.amount, address(this));
        uint256 amountToWithdraw = nUSDLP.balanceOf(address(this));
        nUSDLP.approve(address(swapFlashLoan), amountToWithdraw);
        swapFlashLoan.removeLiquidityOneToken(
            amountToWithdraw,
            tokenIndex,
            (amountToWithdraw * tokenPerLp) / 1e18,
            block.timestamp
        );

        _claimIncentive(SYN);
    }

    function _exit() internal override(Defii, DefiiWithCustomExit) {
        _exitWithParams(exitParams(995));
    }

    function _harvest() internal override {
        miniChef.harvest(pid, address(this));
        _claimIncentive(SYN);
    }

    function _withdrawFunds() internal override {
        _withdrawERC20(USDC);
        _withdrawERC20(USDT);
        _withdrawERC20(BUSD);
    }
}

interface ISwapFlashLoan {
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);
}

interface IMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function harvest(uint256 pid, address to) external;

    function userInfo(uint256 pid, address userAddress)
        external
        view
        returns (UserInfo memory);
}