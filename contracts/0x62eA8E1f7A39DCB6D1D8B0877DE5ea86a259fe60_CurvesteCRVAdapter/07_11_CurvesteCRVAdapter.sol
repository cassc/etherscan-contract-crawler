// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../base/AdapterBase.sol";
import "../../interfaces/curve/ICurveRoutersteCRV.sol";
import "../../interfaces/curve/ICurveLiquidityGaugev2.sol";

contract CurvesteCRVAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "CurvesteCRVAdapter")
    {
        coins[0] = ethAddr;
        coins[1] = stethAddr;
    }

    event CurveExchange(
        address account,
        int128 fromIndex,
        int128 toIndex,
        uint256 dx,
        uint256 giveBack
    );

    event CurveAddLiquidity(
        address account,
        uint256[2] amountsIn,
        uint256 giveBack
    );

    event CurveRemoveLiquidity(
        address account,
        uint256 removeAmount,
        uint256 giveBack0,
        uint256 giveBack1
    );

    event CurveRemoveLiquidityOneCoin(
        address account,
        uint256 removeAmount,
        int128 tokenIndex,
        uint256 giveBack
    );

    event CurveDeposit(address account, address farmAddr, uint256 amount);
    event CurveWithdraw(address account, address farmAddr, uint256 amount);
    event CurveClaimRewards(address account, address farmAddr);

    address public constant routerAddr =
        0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    address public constant lpAddr = 0x06325440D014e39736583c165C2963BA99fAf14E;
    address public constant farmAddr =
        0x182B723a58739a9c974cFDB385ceaDb237453c28;

    address public stethAddr = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    mapping(int128 => address) public coins;

    function exchange(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        (int128 fromIndex, int128 toIndex, uint256 dx, uint256 min_dy) = abi
            .decode(encodedData, (int128, int128, uint256, uint256));
        if (fromIndex == 1) {
            pullAndApprove(coins[fromIndex], account, routerAddr, dx);
        }

        uint256 giveBack = ICurveRoutersteCRV(routerAddr).exchange{
            value: msg.value
        }(fromIndex, toIndex, dx, min_dy);
        returnAsset(coins[toIndex], account, giveBack);

        emit CurveExchange(account, fromIndex, toIndex, dx, giveBack);
    }

    function addLiquidity(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        /// @param amountsIn the amounts to add,
        /// @param minMintAmount the minimum lp token amount to be minted and returned to the user
        (uint256[2] memory amountsIn, uint256 minMintAmount) = abi.decode(
            encodedData,
            (uint256[2], uint256)
        );
        pullAndApprove(coins[1], account, routerAddr, amountsIn[1]);
        uint256 giveBack = ICurveRoutersteCRV(routerAddr).add_liquidity{
            value: msg.value
        }(amountsIn, minMintAmount);
        returnAsset(lpAddr, account, giveBack);

        emit CurveAddLiquidity(account, amountsIn, giveBack);
    }

    function removeLiquidity(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        /// @param removeAmount amount of the lp token to remove liquidity
        /// @param minAmounts the minimum amounts of the (underlying) tokens to return to the user
        (uint256 removeAmount, uint256[2] memory minAmounts) = abi.decode(
            encodedData,
            (uint256, uint256[2])
        );
        pullAndApprove(lpAddr, account, routerAddr, removeAmount);
        uint256[2] memory giveBack = ICurveRoutersteCRV(routerAddr)
            .remove_liquidity(removeAmount, minAmounts);

        returnAsset(coins[0], account, giveBack[0]);
        returnAsset(coins[1], account, giveBack[1]);

        emit CurveRemoveLiquidity(
            account,
            removeAmount,
            giveBack[0],
            giveBack[1]
        );
    }

    function removeLiquidityOneCoin(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        /// @param tokenIndex 0 for eth; 1 for steth
        /// @param lpAmount the amount of the lp to remove
        /// @param minAmount the minimum amount to return to the user
        (int128 tokenIndex, uint256 lpAmount, uint256 minAmount) = abi.decode(
            encodedData,
            (int128, uint256, uint256)
        );
        pullAndApprove(lpAddr, account, routerAddr, lpAmount);
        uint256 giveBack = ICurveRoutersteCRV(routerAddr)
            .remove_liquidity_one_coin(lpAmount, tokenIndex, minAmount);
        returnAsset(coins[tokenIndex], account, giveBack);

        emit CurveRemoveLiquidityOneCoin(
            account,
            lpAmount,
            tokenIndex,
            giveBack
        );
    }

    function deposit(uint256 amountDeposit) external onlyDelegation {
        ICurveLiquidityGaugev2(farmAddr).deposit(amountDeposit);

        emit CurveDeposit(address(this), farmAddr, amountDeposit);
    }

    function withdraw(uint256 amountWithdraw) external onlyDelegation {
        ICurveLiquidityGaugev2(farmAddr).withdraw(amountWithdraw);

        emit CurveWithdraw(address(this), farmAddr, amountWithdraw);
    }

    function claimRewards() external onlyDelegation {
        ICurveLiquidityGaugev2(farmAddr).claim_rewards();

        emit CurveClaimRewards(address(this), farmAddr);
    }
}