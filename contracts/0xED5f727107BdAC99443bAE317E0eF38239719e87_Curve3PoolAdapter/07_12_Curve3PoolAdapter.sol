// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../base/AdapterBase.sol";
import "../../interfaces/curve/ICurveRouter3Pool.sol";
import "../../interfaces/curve/ICurveLpToken.sol";
import "../../interfaces/curve/ICurveLiquidityGauge.sol";

contract Curve3PoolAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "Curve3PoolAdapter")
    {
        coins[0] = ICurveRouter3Pool(routerAddr).coins(0);
        coins[1] = ICurveRouter3Pool(routerAddr).coins(1);
        coins[2] = ICurveRouter3Pool(routerAddr).coins(2);
    }

    address public constant routerAddr =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant lpAddr = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant farmAddr =
        0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;

    mapping(int128 => address) public coins;

    function exchange(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (int128 fromIndex, int128 toIndex, uint256 dx, uint256 min_dy) = abi
            .decode(encodedData, (int128, int128, uint256, uint256));
        pullAndApprove(coins[fromIndex], account, routerAddr, dx);
        IERC20 tokenTo = IERC20(coins[toIndex]);
        uint256 balanceBefore = tokenTo.balanceOf(address(this));
        ICurveRouter3Pool(routerAddr).exchange(fromIndex, toIndex, dx, min_dy);
        uint256 balanceAfter = tokenTo.balanceOf(address(this));
        returnAsset(coins[toIndex], account, balanceAfter - balanceBefore);
    }

    function addLiquidity(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (uint256[3] memory amountsIn, uint256 minMintAmount) = abi.decode(
            encodedData,
            (uint256[3], uint256)
        );
        pullAndApprove(coins[0], account, routerAddr, amountsIn[0]);
        pullAndApprove(coins[1], account, routerAddr, amountsIn[1]);
        pullAndApprove(coins[2], account, routerAddr, amountsIn[2]);

        uint256 tokenBefore = IERC20(lpAddr).balanceOf(address(this));
        ICurveRouter3Pool(routerAddr).add_liquidity(amountsIn, minMintAmount);
        uint256 tokenAfter = IERC20(lpAddr).balanceOf(address(this));
        returnAsset(lpAddr, account, tokenAfter - tokenBefore);
    }

    function removeLiquidity(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (uint256 removeAmount, uint256[3] memory minAmounts) = abi.decode(
            encodedData,
            (uint256, uint256[3])
        );
        pullAndApprove(lpAddr, account, routerAddr, removeAmount);
        uint256[3] memory amountsBefore;

        amountsBefore[0] = IERC20(coins[0]).balanceOf(address(this));
        amountsBefore[1] = IERC20(coins[1]).balanceOf(address(this));
        amountsBefore[2] = IERC20(coins[2]).balanceOf(address(this));
        ICurveRouter3Pool(routerAddr).remove_liquidity(
            removeAmount,
            minAmounts
        );
        uint256[3] memory amountsDiff;
        amountsDiff[0] =
            IERC20(coins[0]).balanceOf(address(this)) -
            amountsBefore[0];
        amountsDiff[1] =
            IERC20(coins[1]).balanceOf(address(this)) -
            amountsBefore[1];
        amountsDiff[2] =
            IERC20(coins[2]).balanceOf(address(this)) -
            amountsBefore[2];
        returnAsset(coins[0], account, amountsDiff[0]);
        returnAsset(coins[1], account, amountsDiff[1]);
        returnAsset(coins[2], account, amountsDiff[2]);
    }

    function removeLiquidityOneCoin(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (int128 tokenIndex, uint256 lpAmount, uint256 minAmount) = abi.decode(
            encodedData,
            (int128, uint256, uint256)
        );

        pullAndApprove(lpAddr, account, routerAddr, lpAmount);
        IERC20 tokenGet = IERC20(coins[tokenIndex]);
        uint256 amountBefore = tokenGet.balanceOf(address(this));
        ICurveRouter3Pool(routerAddr).remove_liquidity_one_coin(
            lpAmount,
            tokenIndex,
            minAmount
        );
        uint256 amountAfter = tokenGet.balanceOf(address(this));
        returnAsset(coins[tokenIndex], account, amountAfter - amountBefore);
    }

    function deposit(uint256 amountDeposit) external onlyDelegation {
        ICurveLiquidityGauge(farmAddr).deposit(amountDeposit);
    }

    function withdraw(uint256 amountWithdraw) external onlyDelegation {
        ICurveLiquidityGauge(farmAddr).withdraw(amountWithdraw);
    }

    function claimRewards() external onlyDelegation {
        ICurveLiquidityGauge(farmAddr).withdraw(0);
    }
}