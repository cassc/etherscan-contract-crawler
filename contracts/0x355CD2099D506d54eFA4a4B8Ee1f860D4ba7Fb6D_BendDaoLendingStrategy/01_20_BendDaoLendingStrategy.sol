// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ILendingPool} from "../interfaces/benddao/ILendingPool.sol";
import {IIncentivesController} from "../interfaces/benddao/IIncentivesController.sol";
import {IScaledBalanceToken} from "../interfaces/benddao/IIncentivesController.sol";
import {IUniswapV2Router02} from "../interfaces/uniswap/IUniswapV2Router02.sol";

import {LendingVault} from "../vaults/LendingVault.sol";

import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

error NoRewardsToSwap();
error NoRewardsToClaim();

/// @title BenddaoLendingStrategy
/// @author Protectorate
/// @notice Strategy for lending assets to BendDao.
contract BendDaoLendingStrategy is Ownable {
    event ClaimRewards(uint256 amount);
    event SwapRewardsForAsset(
        address indexed tokenIn, address indexed tokenOut, uint256 rewardIn, uint256 assetOut
    );

    ILendingPool private constant BENDDAO_LENDING_POOL =
        ILendingPool(0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762);

    IIncentivesController private constant BENDDAO_INCENTIVES_CONTROLLER =
        IIncentivesController(0x26FC1f11E612366d3367fc0cbFfF9e819da91C8d);

    IUniswapV2Router02 private constant UNISWAP_V2_ROUTER_02 =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IERC20 private constant BEND = IERC20(0x0d02755a5700414B26FF040e1dE35D337DF56218);

    IERC20 private constant BTOKEN = IERC20(0xeD1840223484483C0cb050E6fC344d1eBF0778a9);

    /// @dev `WETH` in this case.
    IERC20 private immutable asset;

    LendingVault public immutable lendingVault;

    /// @notice Arguments will be audited in the deployment script.
    constructor(LendingVault _lendingVault) {
        asset = IERC20(_lendingVault.asset());
        lendingVault = _lendingVault;
    }

    /// @notice `lendingVault` will send the requested assets to
    /// this strategy when called.
    /// @dev The call to the lending pool must succeed *completely* or
    /// fail.
    /// @param amount amount to deposit.
    function deposit(uint256 amount) external onlyOwner {
        lendingVault.requestAssets(amount);

        asset.approve(address(BENDDAO_LENDING_POOL), amount);

        BENDDAO_LENDING_POOL.deposit(address(asset), amount, address(this), uint16(0));
    }

    /// @notice only the strategy keeper can withdraw assets from underlying lending protocol.
    /// funds will automatically be directed towards the vault.
    /// @dev It is important that all strategies behave the same. Either allow for lending
    /// protocols to return full/partial amounts.
    /// @param amount amount to withdraw.
    function withdraw(uint256 amount) external onlyOwner returns (uint256 amountWithdrawn) {
        amountWithdrawn = BENDDAO_LENDING_POOL.withdraw(address(asset), amount, address(this));

        asset.approve(address(lendingVault), amountWithdrawn);

        lendingVault.replenishAssets(amountWithdrawn);
    }

    /// @notice Sells `BEND` rewards into `WETH`.
    function swapRewardsForAsset(uint256 amountOutMin, uint256 deadline)
        external
        onlyOwner
        returns (uint256)
    {
        uint256 balance = BEND.balanceOf(address(this));

        if (balance == 0) revert NoRewardsToSwap();

        address[] memory path = new address[](2);

        path[0] = address(BEND);
        path[1] = address(asset);

        BEND.approve(address(UNISWAP_V2_ROUTER_02), balance);

        uint256[] memory amounts = UNISWAP_V2_ROUTER_02.swapExactTokensForTokens(
            balance, amountOutMin, path, address(lendingVault), deadline
        );

        emit SwapRewardsForAsset(address(BEND), address(asset), amounts[0], amounts[1]);

        return amounts[1];
    }

    /// @notice Method to claim `BEND` rewards from BendDAO.
    function claimRewards() external {
        IScaledBalanceToken[] memory assets = new IScaledBalanceToken[](1);
        assets[0] = IScaledBalanceToken(address(BTOKEN));

        uint256 unclaimedRewards =
            BENDDAO_INCENTIVES_CONTROLLER.getRewardsBalance(assets, address(this));

        if (unclaimedRewards == 0) revert NoRewardsToClaim();

        uint256 claimedRewards =
            BENDDAO_INCENTIVES_CONTROLLER.claimRewards(assets, unclaimedRewards);

        emit ClaimRewards(claimedRewards);
    }

    /// @notice This method refers to how many assets the strategy has
    /// lent to the underlying lending protocol (interest bearing).
    function allocatedAssets() external view returns (uint256) {
        return BTOKEN.balanceOf(address(this));
    }
}