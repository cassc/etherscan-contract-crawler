// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../Strategy.sol";
import "../connectors/Chainlink.sol";
import {IWombatAsset, IWombatRouter} from "../connectors/Wombat.sol";
import "../connectors/Wombex.sol";
import "../connectors/PancakeV2.sol";


contract StrategyWombexUsdt is Strategy {

    // --- structs

    struct StrategyParams {
        address usdt;
        address busd;
        address wom;
        address wmx;
        address lpUsdt;
        address wmxLpUsdt;
        address poolDepositor;
        address pool;
        address pancakeRouter;
        address wombatRouter;
        address oracleUsdt;
        string name;
    }

    // --- params

    IERC20 public usdt;

    IERC20 public wom;
    IERC20 public wmx;

    IWombatAsset public lpUsdt;
    IWombexBaseRewardPool public wmxLpUsdt;
    IWombexPoolDepositor public poolDepositor;
    address public pool;
    IPancakeRouter02 public pancakeRouter;
    IWombatRouter public wombatRouter;
    IPriceFeed public oracleBusd;
    IPriceFeed public oracleUsdt;
    uint256 public usdtDm;
    uint256 public lpUsdtDm;

    IERC20 public busd;
    string public name;



    // --- events

    event StrategyUpdatedParams();

    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}



    function initialize() initializer public {
        __Strategy_init();
    }

    // --- Setters

    function setParams(StrategyParams calldata params) external onlyAdmin {
        usdt = IERC20(params.usdt);
        busd = IERC20(params.busd);
        wom = IERC20(params.wom);
        wmx = IERC20(params.wmx);

        lpUsdt = IWombatAsset(params.lpUsdt);
        wmxLpUsdt = IWombexBaseRewardPool(params.wmxLpUsdt);
        poolDepositor = IWombexPoolDepositor(params.poolDepositor);
        pool = params.pool;

        pancakeRouter = IPancakeRouter02(params.pancakeRouter);

        lpUsdtDm = 10 ** IERC20Metadata(params.lpUsdt).decimals();

        name = string(params.name);

        emit StrategyUpdatedParams();
    }

    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(usdt), "Some token not compatible");

        // get LP amount min
        uint256 usdtBalance = usdt.balanceOf(address(this));
        (uint256 lpUsdtAmount,) = poolDepositor.getDepositAmountOut(address(lpUsdt), usdtBalance);
        uint256 lpUsdtAmountMin = OvnMath.subBasisPoints(lpUsdtAmount, stakeSlippageBP);

        // deposit
        usdt.approve(address(poolDepositor), usdtBalance);
        poolDepositor.deposit(address(lpUsdt), usdtBalance, lpUsdtAmountMin, true);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdt), "Some token not compatible");

        // get withdraw amount for 1 LP
        (uint256 usdtAmountOneAsset,) = poolDepositor.getWithdrawAmountOut(address(lpUsdt), lpUsdtDm);

        // get LP amount
        uint256 lpUsdtAmount = OvnMath.addBasisPoints(_amount, stakeSlippageBP) * lpUsdtDm / usdtAmountOneAsset;

        // withdraw
        wmxLpUsdt.approve(address(poolDepositor), lpUsdtAmount);
        poolDepositor.withdraw(address(lpUsdt), lpUsdtAmount, _amount, address(this));

        return usdt.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(usdt), "Some token not compatible");

        // get usdt amount min
        uint256 lpUsdtBalance = wmxLpUsdt.balanceOf(address(this));
        if (lpUsdtBalance == 0) {
            return usdt.balanceOf(address(this));
        }
        (uint256 usdtAmount,) = poolDepositor.getWithdrawAmountOut(address(lpUsdt), lpUsdtBalance);
        uint256 usdtAmountMin = OvnMath.subBasisPoints(usdtAmount, stakeSlippageBP);

        // withdraw
        wmxLpUsdt.approve(address(poolDepositor), lpUsdtBalance);
        poolDepositor.withdraw(address(lpUsdt), lpUsdtBalance, usdtAmountMin, address(this));

        return usdt.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue();
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256) {
        uint256 usdtBalance = usdt.balanceOf(address(this));

        uint256 lpUsdtBalance = wmxLpUsdt.balanceOf(address(this));
        if (lpUsdtBalance > 0) {
            (uint256 usdtAmount,) = poolDepositor.getWithdrawAmountOut(address(lpUsdt), lpUsdtBalance);
            usdtBalance += usdtAmount;
        }

        return usdtBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        uint256 lpUsdtBalance = wmxLpUsdt.balanceOf(address(this));
        if (lpUsdtBalance > 0) {
            wmxLpUsdt.getReward(address(this), false);
        }

        // sell rewards
        uint256 totalUsdt;

        uint256 womBalance = wom.balanceOf(address(this));
        if (womBalance > 0) {
            uint256 amountOut = PancakeSwapLibrary.getAmountsOut(
                pancakeRouter,
                address(wom),
                address(busd),
                address(usdt),
                womBalance
            );
            if (amountOut > 0) {
                totalUsdt += PancakeSwapLibrary.swapExactTokensForTokens(
                    pancakeRouter,
                    address(wom),
                    address(busd),
                    address(usdt),
                    womBalance,
                    amountOut * 99 / 100,
                    address(this)
                );
            }
        }

        uint256 wmxBalance = wmx.balanceOf(address(this));
        if (wmxBalance > 0) {
            uint256 amountOut = PancakeSwapLibrary.getAmountsOut(
                pancakeRouter,
                address(wmx),
                address(busd),
                address(usdt),
                wmxBalance
            );
            if (amountOut > 0) {
                totalUsdt += PancakeSwapLibrary.swapExactTokensForTokens(
                    pancakeRouter,
                    address(wmx),
                    address(busd),
                    address(usdt),
                    wmxBalance,
                    amountOut * 99 / 100,
                    address(this)
                );
            }
        }

        if (totalUsdt > 0) {
            usdt.transfer(_to, totalUsdt);
        }

        return totalUsdt;
    }

}