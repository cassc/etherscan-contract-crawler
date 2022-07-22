// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/ISwapRouter02.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
import "./libs/ZapLib.sol";
import "./interfaces/ICurve.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IAaveOracle.sol";
import "./interfaces/IBaseToUsdAssimilator.sol";

contract XaveStratXSGDUSDCIndexUSDC is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Addresses {
        address usdc;
        address xsgd;
        address indexUsdc;
        address ammCurve;
        address assimUsdc;
        address assimXsgd;
        address lendingPool;
        address lendingHToken;
        address lendingUsdcVariableDebtToken;
        address lendingOracle;
        address uniswapRouter;
        address uniswapPool;
    }

    uint256 public constant PRECISION = 1e6;

    uint256 private constant XSGD_DECIMALS = 1e6;
    uint256 private constant USDC_DECIMALS = 1e6;
    uint256 private constant ASSIMILATOR_DECIMALS = 1e8;
    uint256 private constant ETH_DECIMALS = 1e18;

    Addresses public addresses;
    uint256 public collateralizationRatio;
    uint256 public interestRateMode;
    uint24 public uniswapPoolFee;

    event ZappedIn(
        uint256 tokenInAmount,
        address tokenInAddress,
        uint256 tokenOutAmount,
        address tokenOutAddress
    );
    event ZappedOut(
        uint256 tokenInAmount,
        address tokenInAddress,
        uint256 tokenOutAmount,
        address tokenOutAddress
    );

    constructor(
        Addresses memory _addresses,
        uint256 _collateralizationRatio,
        uint256 _interestRateMode,
        uint24 _uniswapPoolFee
    ) {
        addresses = _addresses;
        collateralizationRatio = _collateralizationRatio;
        interestRateMode = _interestRateMode;
        uniswapPoolFee = _uniswapPoolFee;
    }

    function setAddresses(Addresses memory _addresses) public onlyOwner {
        addresses = _addresses;
    }

    function setCollateralizationRatio(uint256 _collateralizationRatio)
        public
        onlyOwner
    {
        collateralizationRatio = _collateralizationRatio;
    }

    function setInterestRateMode(uint256 _interestRateMode) public onlyOwner {
        interestRateMode = _interestRateMode;
    }

    function setUniswapPoolFee(uint24 _uniswapPoolFee) public onlyOwner {
        uniswapPoolFee = _uniswapPoolFee;
    }

    function zapIn(
        uint256 amount,
        address tokenAddress,
        uint256 deadline,
        uint256 slippage
    ) external returns (uint256) {
        require(
            tokenAddress == addresses.xsgd || tokenAddress == addresses.usdc,
            "XaveStrat/unsupported-token"
        );

        addLiquidity(tokenAddress, amount, deadline, slippage);

        depositAndBorrow();

        uint256 usdcBalance = IERC20(addresses.usdc).balanceOf(address(this));
        uint256 indexUSDCReceived = swap(
            addresses.usdc,
            addresses.indexUsdc,
            msg.sender,
            usdcBalance,
            slippage
        );

        transferBalances();

        emit ZappedIn(
            amount,
            tokenAddress,
            indexUSDCReceived,
            addresses.indexUsdc
        );

        return indexUSDCReceived;
    }

    function zapOut(
        uint256 amount,
        address tokenAddress,
        uint256 deadline,
        uint256 slippage
    ) external returns (uint256) {
        // Check if supported token
        require(
            tokenAddress == addresses.xsgd || tokenAddress == addresses.usdc,
            "XaveStrat/unsupported-token"
        );

        // Check if user already paid USDC loan
        uint256 debtTokenBalance = IERC20(
            addresses.lendingUsdcVariableDebtToken
        ).balanceOf(address(msg.sender));
        require(debtTokenBalance > 0, "XaveStrat/loan-repaid");

        // Check if user already withdraw HLP collateral
        uint256 hTokenBalance = IERC20(addresses.lendingHToken).balanceOf(
            address(msg.sender)
        );
        require(hTokenBalance > 0, "XaveStrat/collateral-withdrawn");

        IERC20(addresses.indexUsdc).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        swap(
            addresses.indexUsdc,
            addresses.usdc,
            address(this),
            amount,
            slippage
        );

        repayAndWithdraw();

        uint256 tokensReceived = removeLiquidity(tokenAddress, deadline);

        transferBalances();

        emit ZappedOut(
            amount,
            addresses.indexUsdc,
            tokensReceived,
            tokenAddress
        );

        return tokensReceived;
    }

    function addLiquidity(
        address tokenAddress,
        uint256 amount,
        uint256 deadline,
        uint256 slippage
    ) internal {
        uint256 numeraire = 0;
        if (tokenAddress == addresses.xsgd) {
            uint256 rate = IBaseToUsdAssimilator(addresses.assimXsgd).getRate();
            numeraire = ((amount.mul(rate)).div(ASSIMILATOR_DECIMALS)).div(
                XSGD_DECIMALS
            );
        } else {
            uint256 rate = IBaseToUsdAssimilator(addresses.assimUsdc).getRate();
            numeraire = ((amount.mul(rate)).div(ASSIMILATOR_DECIMALS)).div(
                USDC_DECIMALS
            );
        }
        uint256 minLpTokens = numeraire
            .sub(numeraire.mul(slippage).div(PRECISION))
            .mul(ETH_DECIMALS);

        ZapLib.zap(
            addresses.ammCurve,
            amount,
            deadline,
            minLpTokens,
            tokenAddress != addresses.usdc
        );
    }

    function depositAndBorrow() internal {
        uint256 hlpBalance = IERC20(addresses.ammCurve).balanceOf(
            address(this)
        );

        IERC20(addresses.ammCurve).safeApprove(addresses.lendingPool, 0);
        IERC20(addresses.ammCurve).safeApprove(
            addresses.lendingPool,
            hlpBalance
        );

        (uint256 totalCollateralETHBeforeDeposit, , , , , ) = ILendingPool(
            addresses.lendingPool
        ).getUserAccountData(msg.sender);

        ILendingPool(addresses.lendingPool).deposit(
            addresses.ammCurve,
            hlpBalance,
            msg.sender, // account will receive H tokens while this contract provides HLP collateral
            0 // referral code is now inactive, for future use
        );

        (uint256 totalCollateralETHAfterDeposit, , , , , ) = ILendingPool(
            addresses.lendingPool
        ).getUserAccountData(msg.sender);

        uint256 totalCollateralETH = totalCollateralETHAfterDeposit -
            totalCollateralETHBeforeDeposit;

        uint256 maxBorrowInETH = totalCollateralETH
            .mul(collateralizationRatio)
            .div(PRECISION);

        uint256 usdcPriceInETH = IAaveOracle(addresses.lendingOracle)
            .getAssetPrice(addresses.usdc);

        uint256 usdcToBorrow = maxBorrowInETH.mul(USDC_DECIMALS).div(
            usdcPriceInETH
        );

        ILendingPool(addresses.lendingPool).borrow(
            addresses.usdc,
            usdcToBorrow,
            interestRateMode,
            0, // referral code is now inactive, for future use
            msg.sender // account will receive debt tokens while this contract receives USDC
        );
    }

    function swap(
        address originTokenAddress,
        address targetTokenAddress,
        address recipientAddress,
        uint256 amount,
        uint256 slippage
    ) internal returns (uint256) {
        IERC20(originTokenAddress).safeApprove(addresses.uniswapRouter, 0);
        IERC20(originTokenAddress).safeApprove(addresses.uniswapRouter, amount);

        (int24 tick, ) = OracleLibrary.consult(addresses.uniswapPool, 1);
        uint256 amountOut = OracleLibrary.getQuoteAtTick(
            tick,
            uint128(amount),
            originTokenAddress,
            targetTokenAddress
        );

        uint256 minAmountOut = amountOut.sub(
            amountOut.mul(slippage).div(PRECISION)
        );

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: originTokenAddress,
                tokenOut: targetTokenAddress,
                fee: uniswapPoolFee,
                recipient: recipientAddress,
                amountIn: amount,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });
            
        // doc: https://docs.uniswap.org/protocol/guides/swaps/single-swaps#call-the-function
        uint256 amountReceived = ISwapRouter02(addresses.uniswapRouter)
            .exactInputSingle(params);

        return amountReceived;
    }

    function repayAndWithdraw() internal {
        uint256 usdcBalance = IERC20(addresses.usdc).balanceOf(address(this));

        IERC20(addresses.usdc).safeApprove(addresses.lendingPool, 0);
        IERC20(addresses.usdc).safeApprove(addresses.lendingPool, usdcBalance);

        (, uint256 totalDebtETHBeforeRepay, , , , ) = ILendingPool(
            addresses.lendingPool
        ).getUserAccountData(msg.sender);

        ILendingPool(addresses.lendingPool).repay(
            addresses.usdc,
            usdcBalance,
            interestRateMode,
            msg.sender
        );

        (
            uint256 totalCollateralETH,
            uint256 totalDebtETHAfterRepay,
            ,
            ,
            ,

        ) = ILendingPool(addresses.lendingPool).getUserAccountData(msg.sender);

        uint256 repayPercentage = uint256(1 ether).sub(
            totalDebtETHAfterRepay.mul(ETH_DECIMALS).div(
                totalDebtETHBeforeRepay
            )
        );

        uint256 maxWithdrawInETH = totalCollateralETH.mul(repayPercentage).div(
            ETH_DECIMALS
        );

        uint256 hlpPriceInETH = IAaveOracle(addresses.lendingOracle)
            .getAssetPrice(addresses.ammCurve);

        uint256 withdrawAmount = (totalDebtETHAfterRepay == 0)
            ? type(uint256).max // withdraw everything if debt is totally paid
            : maxWithdrawInETH.mul(ETH_DECIMALS).div(hlpPriceInETH);

        IERC20(addresses.lendingHToken).safeTransferFrom(
            msg.sender,
            address(this),
            withdrawAmount
        );

        ILendingPool(addresses.lendingPool).withdraw(
            addresses.ammCurve,
            withdrawAmount, // amount
            address(this)
        );
    }

    function removeLiquidity(address tokenAddress, uint256 deadline)
        internal
        returns (uint256)
    {
        uint256 hlpBalance = IERC20(addresses.ammCurve).balanceOf(
            address(this)
        );

        uint256[] memory withdrawals = ICurve(addresses.ammCurve).withdraw(
            hlpBalance,
            deadline
        );

        if (tokenAddress == addresses.xsgd) {
            IERC20(addresses.usdc).safeApprove(addresses.ammCurve, 0);
            IERC20(addresses.usdc).safeApprove(
                addresses.ammCurve,
                withdrawals[1]
            );

            uint256 targetAmount = ICurve(addresses.ammCurve).viewOriginSwap(
                addresses.usdc,
                addresses.xsgd,
                withdrawals[1]
            );

            ICurve(addresses.ammCurve).originSwap(
                addresses.usdc,
                addresses.xsgd,
                withdrawals[1],
                targetAmount,
                deadline
            );

            return IERC20(addresses.xsgd).balanceOf(address(this));
        } else {
            IERC20(addresses.xsgd).safeApprove(addresses.ammCurve, 0);
            IERC20(addresses.xsgd).safeApprove(
                addresses.ammCurve,
                withdrawals[0]
            );

            uint256 targetAmount = ICurve(addresses.ammCurve).viewOriginSwap(
                addresses.xsgd,
                addresses.usdc,
                withdrawals[0]
            );

            ICurve(addresses.ammCurve).originSwap(
                addresses.xsgd,
                addresses.usdc,
                withdrawals[0],
                targetAmount,
                deadline
            );

            return IERC20(addresses.usdc).balanceOf(address(this));
        }
    }

    function transferBalances() internal {
        uint256 indexUsdcBalanceLeft = IERC20(addresses.indexUsdc).balanceOf(
            address(this)
        );
        uint256 xsgdBalanceLeft = IERC20(addresses.xsgd).balanceOf(
            address(this)
        );
        uint256 usdcBalanceLeft = IERC20(addresses.usdc).balanceOf(
            address(this)
        );
        uint256 hTokenBalanceLeft = IERC20(addresses.lendingHToken).balanceOf(
            address(this)
        );

        if (indexUsdcBalanceLeft > 0) {
            IERC20(addresses.indexUsdc).safeTransfer(
                msg.sender,
                indexUsdcBalanceLeft
            );
        }
        if (xsgdBalanceLeft > 0) {
            IERC20(addresses.xsgd).safeTransfer(msg.sender, xsgdBalanceLeft);
        }
        if (usdcBalanceLeft > 0) {
            IERC20(addresses.usdc).safeTransfer(msg.sender, usdcBalanceLeft);
        }
        if (hTokenBalanceLeft > 0) {
            IERC20(addresses.lendingHToken).safeTransfer(
                msg.sender,
                hTokenBalanceLeft
            );
        }
    }
}