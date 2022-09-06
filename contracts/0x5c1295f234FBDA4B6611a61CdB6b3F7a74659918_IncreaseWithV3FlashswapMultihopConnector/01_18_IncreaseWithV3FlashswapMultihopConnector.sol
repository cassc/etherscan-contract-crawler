// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol';
import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import '@uniswap/v3-periphery/contracts/libraries/Path.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';

import '../interfaces/IIncreaseWithV3FlashswapMultihopConnector.sol';
import '../../modules/Lender/LendingDispatcher.sol';
import '../../modules/FundsManager/FundsManager.sol';
import '../../modules/Flashswapper/FlashswapStorage.sol';

contract IncreaseWithV3FlashswapMultihopConnector is
    LendingDispatcher,
    FundsManager,
    FlashswapStorage,
    IIncreaseWithV3FlashswapMultihopConnector
{
    using Path for bytes;
    using BytesLib for bytes;
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

    address private immutable SELF_ADDRESS;
    address private immutable factory;

    constructor(
        uint256 _principal,
        uint256 _profit,
        address _holder,
        address _factory
    ) public FundsManager(_principal, _profit, _holder) {
        SELF_ADDRESS = address(this);
        factory = _factory;
    }

    function increasePositionWithV3FlashswapMultihop(IncreaseWithV3FlashswapMultihopParams calldata params)
        external
        override
        onlyAccountOwnerOrRegistry
    {
        require(params.supplyAmount >= params.principalAmount, 'IWV3FMC1');
        _verifySetup(params.platform, params.supplyToken, params.borrowToken);

        if (params.principalAmount > 0) addPrincipal(params.principalAmount);

        uint256 flashAmount = params.supplyAmount - params.principalAmount;

        if (flashAmount > 0) {
            if (params.supplyToken != params.borrowToken) {
                exactOutputInternal(
                    flashAmount,
                    SwapCallbackData(
                        params.principalAmount,
                        params.supplyAmount,
                        params.maxBorrowAmount,
                        params.platform,
                        params.path
                    )
                );
            } else {
                requestFlashloan(
                    params.supplyToken,
                    FlashCallbackData(params.principalAmount, flashAmount, params.platform, params.path)
                );
            }
        } else {
            _increasePosition(params.platform, params.supplyToken, params.principalAmount, params.borrowToken, 0);
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

        // If too much slippage was found in some parts of the path, this will revert early
        require(amountOutReceived == amountOut, 'IWV3FMC2');
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        _verifyCallbackAndClear();

        // Required as in UniswapRouter: not tested
        require(amount0Delta > 0 || amount1Delta > 0, 'IWV3FMC3'); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (, address owedToken, ) = data.path.decodeFirstPool();

        uint256 amountToPay = uint256(amount0Delta > 0 ? amount0Delta : amount1Delta);

        if (data.path.hasMultiplePools()) {
            data.path = data.path.skipToken();
            exactOutputInternal(amountToPay, data);
        } else {
            require(amountToPay <= data.maxBorrowAmount, 'IWV3FMC4');
            require(owedToken == simplePositionStore().borrowToken, 'IWV3FMC5');

            _increasePosition(
                data.platform,
                simplePositionStore().supplyToken,
                data.supplyAmount,
                owedToken,
                amountToPay
            );
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
            revert('IWV3FMC7');
        }

        IUniswapV3PoolActions(pool).flash(
            address(this),
            flashToken0 ? data.flashAmount : 0,
            flashToken0 ? 0 : data.flashAmount,
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
        uint256 owedAmount = fee0 > 0 ? data.flashAmount + fee0 : data.flashAmount + fee1;
        _increasePosition(data.platform, supplyToken, data.principalAmount + data.flashAmount, supplyToken, owedAmount);

        IERC20(supplyToken).safeTransfer(msg.sender, owedAmount);
    }

    /*************************************/
    /************** Helpers **************/
    /*************************************/

    function _increasePosition(
        address platform,
        address supplyToken,
        uint256 amountToSupply,
        address borrowToken,
        uint256 amountToBorrow
    ) internal {
        address lender = getLender(platform);
        supply(lender, platform, supplyToken, amountToSupply);
        borrow(lender, platform, borrowToken, amountToBorrow);
    }

    function _verifySetup(
        address platform,
        address supplyToken,
        address borrowToken
    ) internal {
        address lender = getLender(platform);

        if (isSimplePosition()) {
            requireSimplePositionDetails(platform, supplyToken, borrowToken);
        } else {
            simplePositionStore().platform = platform;
            simplePositionStore().supplyToken = supplyToken;
            simplePositionStore().borrowToken = borrowToken;

            address[] memory markets = new address[](2);
            markets[0] = supplyToken;
            markets[1] = borrowToken;
            enterMarkets(lender, platform, markets);
        }
    }

    function _setExpectedCallback(address pool, bytes4 expectedCallbackSig) internal {
        aStore().callbackTarget = SELF_ADDRESS;
        aStore().expectedCallbackSig = expectedCallbackSig;
        flashswapStore().expectedCaller = pool;
    }

    function _verifyCallbackAndClear() internal {
        // Verify and clear authorisations for callbacks
        require(msg.sender == flashswapStore().expectedCaller, 'IWV3FMC6');
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
}