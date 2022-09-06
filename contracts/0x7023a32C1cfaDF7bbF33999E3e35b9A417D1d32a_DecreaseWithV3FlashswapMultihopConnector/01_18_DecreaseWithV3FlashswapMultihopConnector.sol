// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol';
import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import '@uniswap/v3-periphery/contracts/libraries/Path.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';

import '../interfaces/IDecreaseWithV3FlashswapMultihopConnector.sol';
import '../../modules/Lender/LendingDispatcher.sol';
import '../../modules/FundsManager/FundsManager.sol';
import '../../modules/Flashswapper/FlashswapStorage.sol';

contract DecreaseWithV3FlashswapMultihopConnector is
    LendingDispatcher,
    FundsManager,
    FlashswapStorage,
    IDecreaseWithV3FlashswapMultihopConnector
{
    using Path for bytes;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeCast for uint256;

    /// @dev See Uniswap V3 's TickMath
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    bytes4 internal constant UNISWAPV3_SWAP_CALLBACK_SIG =
        bytes4(keccak256('uniswapV3SwapCallback(int256,int256,bytes)'));
    bytes4 internal constant UNISWAPV3_FLASH_CALLBACK_SIG =
        bytes4(keccak256('uniswapV3FlashCallback(uint256,uint256,bytes)'));

    uint256 private immutable rewardsFactor;
    address private immutable SELF_ADDRESS;
    address private immutable factory;

    constructor(
        uint256 _principal,
        uint256 _profit,
        uint256 _rewardsFactor,
        address _holder,
        address _factory
    ) public FundsManager(_principal, _profit, _holder) {
        SELF_ADDRESS = address(this);
        rewardsFactor = _rewardsFactor;
        factory = _factory;
    }

    function decreasePositionWithV3FlashswapMultihop(DecreaseWithV3FlashswapMultihopConnectorParams calldata params)
        external
        override
        onlyAccountOwner
    {
        _verifySetup(params.platform, params.supplyToken, params.borrowToken);

        address lender = getLender(params.platform); // Get it once, pass it around and use when needed

        uint256 positionDebt = getBorrowBalance(lender, params.platform, params.borrowToken); // Same as above

        if (positionDebt == 0) {
            require(params.withdrawAmount == uint256(-1));
            uint256 withdrawableAmount = getSupplyBalance(lender, params.platform, params.supplyToken);
            redeemSupply(lender, params.platform, params.supplyToken, withdrawableAmount);
            withdraw(withdrawableAmount, withdrawableAmount);
            claimRewards();
            return;
        }

        uint256 debtToRepay = params.borrowTokenRepayAmount > positionDebt
            ? positionDebt
            : params.borrowTokenRepayAmount;

        if (params.supplyToken != params.borrowToken) {
            exactOutputInternal(
                // If specified debt to repay is over the position debt, cap it (full debt repayment)
                debtToRepay,
                SwapCallbackData(
                    params.withdrawAmount,
                    params.maxSupplyTokenRepayAmount,
                    params.borrowTokenRepayAmount,
                    positionDebt,
                    params.platform,
                    lender,
                    params.path
                )
            );
        } else {
            requestFlashloan(
                params.supplyToken,
                FlashCallbackData(
                    params.withdrawAmount,
                    debtToRepay,
                    positionDebt,
                    params.platform,
                    lender,
                    params.path
                )
            );
        }

        // If withdrawing completely, assume full position closure
        if (params.withdrawAmount == uint256(-1)) {
            claimRewards();
        }
    }

    /*************************************/
    /************* Flashswap *************/
    /*************************************/

    /// @dev Performs a single exact output swap
    function exactOutputInternal(uint256 amountOut, SwapCallbackData memory data) private {
        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;
        address pool = getPool(tokenIn, tokenOut, fee);

        _setExpectedCallback(pool, UNISWAPV3_SWAP_CALLBACK_SIG);

        (int256 amount0Delta, int256 amount1Delta) = IUniswapV3PoolActions(pool).swap(
            address(this),
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            abi.encode(data)
        );

        uint256 amountOutReceived;
        (, amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));

        // Required as in UniswapRouter: not tested
        require(amountOutReceived == amountOut, 'DWV3FMC2');
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        _verifyCallbackAndClear();

        // Required as in UniswapRouter: not tested
        require(amount0Delta > 0 || amount1Delta > 0, 'DWV3FMC3'); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address receivedToken, address owedToken, ) = data.path.decodeFirstPool();

        if (receivedToken == simplePositionStore().borrowToken) {
            repayBorrow(
                data.lender,
                data.platform,
                receivedToken,
                uint256(amount0Delta < 0 ? -amount0Delta : -amount1Delta)
            );
        }

        uint256 amountToPay = uint256(amount0Delta > 0 ? amount0Delta : amount1Delta);

        if (data.path.hasMultiplePools()) {
            data.path = data.path.skipToken();
            exactOutputInternal(amountToPay, data);
        } else {
            require(owedToken == simplePositionStore().supplyToken, 'DWV3FMC4');
            require(amountToPay <= data.maxSupplyTokenRepayAmount, 'DWV3FMC5');

            uint256 deposit = getSupplyBalance(data.lender, data.platform, owedToken);

            uint256 withdrawableAmount = deposit.sub(amountToPay);
            uint256 amountToWithdraw = withdrawableAmount < data.withdrawAmount
                ? withdrawableAmount
                : data.withdrawAmount;

            redeemSupply(data.lender, data.platform, owedToken, amountToWithdraw + amountToPay);

            if (amountToWithdraw > 0) {
                uint256 debtValue = data
                    .positionDebt
                    .mul(getReferencePrice(data.lender, data.platform, simplePositionStore().borrowToken))
                    .div(getReferencePrice(data.lender, data.platform, owedToken));

                withdraw(amountToWithdraw, debtValue > deposit ? 0 : deposit - debtValue);
            }
        }
        IERC20(owedToken).safeTransfer(msg.sender, amountToPay);
    }

    /*************************************/
    /************* Flashloan *************/
    /*************************************/

    function requestFlashloan(address token, FlashCallbackData memory data) internal {
        (address tokenA, address tokenB, uint24 fee) = data.path.decodeFirstPool();
        address pool = getPool(tokenA, tokenB, fee);
        _setExpectedCallback(pool, UNISWAPV3_FLASH_CALLBACK_SIG);

        bool flashToken0;

        if (token == tokenA) {
            flashToken0 = tokenA < tokenB;
        } else if (token == tokenB) {
            flashToken0 = tokenB < tokenA;
        } else {
            revert('DWV3FMC7');
        }

        IUniswapV3PoolActions(pool).flash(
            address(this),
            flashToken0 ? data.repayAmount : 0,
            flashToken0 ? 0 : data.repayAmount,
            abi.encode(data)
        );
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata _data
    ) external {
        _verifyCallbackAndClear();
        FlashCallbackData memory data = abi.decode(_data, (FlashCallbackData));

        address supplyToken = simplePositionStore().supplyToken;
        uint256 owedAmount = fee0 > 0 ? data.repayAmount + fee0 : data.repayAmount + fee1;

        repayBorrow(data.lender, data.platform, supplyToken, data.repayAmount);

        uint256 deposit = getSupplyBalance(data.lender, data.platform, supplyToken);

        uint256 withdrawableAmount = deposit.sub(owedAmount);
        uint256 amountToWithdraw = withdrawableAmount < data.withdrawAmount ? withdrawableAmount : data.withdrawAmount;

        redeemSupply(data.lender, data.platform, supplyToken, amountToWithdraw + owedAmount);

        if (amountToWithdraw > 0) {
            withdraw(amountToWithdraw, simplePositionStore().principalValue);
        }

        IERC20(supplyToken).safeTransfer(msg.sender, owedAmount);
    }

    function _verifySetup(
        address platform,
        address supplyToken,
        address borrowToken
    ) internal view {
        requireSimplePositionDetails(platform, supplyToken, borrowToken);
    }

    function _setExpectedCallback(address pool, bytes4 expectedCallbackSig) internal {
        aStore().callbackTarget = SELF_ADDRESS;
        aStore().expectedCallbackSig = expectedCallbackSig;
        flashswapStore().expectedCaller = pool;
    }

    function _verifyCallbackAndClear() internal {
        // Verify and clear authorisations for callbacks
        require(msg.sender == flashswapStore().expectedCaller, 'DWV3FMC6');
        delete flashswapStore().expectedCaller;
        delete aStore().callbackTarget;
        delete aStore().expectedCallbackSig;
    }

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (address) {
        return PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    }

    function claimRewards() private {
        require(isSimplePosition(), 'SP1');
        address lender = getLender(simplePositionStore().platform);

        (address rewardsToken, uint256 rewardsAmount) = claimRewards(lender, simplePositionStore().platform);
        if (rewardsToken != address(0)) {
            uint256 subsidy = rewardsAmount.mul(rewardsFactor) / MANTISSA;
            if (subsidy > 0) {
                IERC20(rewardsToken).safeTransfer(holder, subsidy);
            }
            if (rewardsAmount > subsidy) {
                IERC20(rewardsToken).safeTransfer(accountOwner(), rewardsAmount - subsidy);
            }
        }
    }
}