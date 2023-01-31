// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {ICompoundV3USDC} from "./interfaces.sol";
import {BaseLending} from "./BaseLending.sol";
import {IComet, ICompoundRewards} from "../interfaces/external/ICompoundV3.sol";

contract CompoundV3USDC is ICompoundV3USDC, BaseLending {
    using SafeERC20 for IERC20;

    IComet constant comet = IComet(0xc3d688B66703497DAA19211EEdff47f25384cdc3);
    ICompoundRewards constant compoundRewards =
        ICompoundRewards(0x1B0e765F6224C21223AeA2af16c1C46E38885a40);

    function supplyCompoundV3USDC() external onlyOwner {
        _supplyCompoundV3USDC(WBTC);
        _supplyCompoundV3USDC(WETH);
    }

    function borrowCompoundV3USDC(uint256 amount) external onlyOwner {
        comet.withdrawTo(owner, address(USDC), amount);
    }

    function repayCompoundV3USDC() external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        if (balance == 0) return;

        uint256 debt = comet.borrowBalanceOf(address(this));
        if (debt == 0) return;

        comet.supply(address(USDC), balance > debt ? debt : balance);
    }

    function withdrawCompoundV3USDC(IERC20 token, uint256 amount)
        external
        onlyOwner
    {
        comet.withdrawTo(owner, address(token), amount);
    }

    function claimRewardsCompoundV3USDC() external {
        compoundRewards.claimTo(address(comet), address(this), owner, true);
    }

    function _supplyCompoundV3USDC(IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;
        comet.supply(address(token), balance);
    }

    function _postInit() internal virtual override {
        WBTC.safeApprove(address(comet), type(uint256).max);
        WETH.approve(address(comet), type(uint256).max);
        stETH.safeApprove(address(comet), type(uint256).max);
        USDC.safeApprove(address(comet), type(uint256).max);
    }
}