// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/ISwapRouter.sol";
import "./libraries/TickMath.sol";
import './libraries/CallbackValidation.sol';
import "./interfaces/IUniswapV3SwapCallback.sol";
import "./interfaces/IWETH9.sol";

/// @title Flash contract implementation
contract UniswapFlashSwap is Ownable, IUniswapV3SwapCallback, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ISwapRouter internal constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address internal factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    uint256 internal feeRate = 50;

    uint256 internal constant FEE_FACTOR = 100;

    address internal feeReceiver = 0x35C02930a046755CDfe2ECde1fd998F344687960;

    event FlashProfit(address receiver, uint256 amount, uint256 fee);

    struct FlashCallbackData {
        address tokenIn;
        address tokenOut;
        uint24  fee1;
        uint24  fee2;
        address receiver;
    }

    function setFeeRate(uint256 fee) external onlyOwner {
        require(fee <= 100, "Invalid fee rate");
        feeRate = fee;
    }

    function setFeeReceiver(address receiver) external onlyOwner {
        require(receiver != address(0), "Invalid fee receiver");
        feeReceiver = receiver;
    }

    // 1. Sell WETH for quote tokens in the initial pool, interact with the pool swap() directly
    // 2. In the swap fallback, we will get USDC in THIS address, then we sell quote tokens for WETH in
    // another pool with different fee tier through router, expecting get more WETH than we should pay
    // back to pool one. Then we pay we should pay and take the profits
    function initFlashSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        uint24 _fee1,
        uint24 _fee2
    ) external nonReentrant {
        bool zeroForOne = _tokenIn < _tokenOut;

        getPool(_tokenIn, _tokenOut, _fee1).swap(
            address(this),
            zeroForOne,
            -_amount.toInt256(),
            (
            zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1
            ),
            abi.encode(
                FlashCallbackData({
                    tokenIn: _tokenIn,
                    tokenOut: _tokenOut,
                    fee1: _fee1,
                    fee2: _fee2,
                    receiver: msg.sender
                })
            )
        );
    }

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        // swaps entirely within 0-liquidity regions are not supported
        require(amount0Delta > 0 || amount1Delta > 0);
        FlashCallbackData memory data = abi.decode(_data, (FlashCallbackData));
        CallbackValidation.verifyCallback(factory, data.tokenIn, data.tokenOut, data.fee1);

        address tokenIn = data.tokenIn;
        address tokenOut = data.tokenOut;
        uint24 fee2 = data.fee2;
        address receiver = data.receiver;

        uint256 amountToSell = IERC20(tokenOut).balanceOf(address(this));
        _checkAndAdjustERC20Allowance(tokenOut, amountToSell);
        // call exactInputSingle for swapping tokenOut to tokenIn
        // we should get WETH
        uint256 amountOutInNextPool =
            swapRouter.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenOut,
                    tokenOut: tokenIn,
                    fee: fee2,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountToSell,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );

        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0
                ? (data.tokenIn < data.tokenOut, uint256(amount0Delta))
                : (data.tokenOut < data.tokenIn, uint256(amount1Delta));

        require(amountOutInNextPool > amountToPay, "No profit!");
        if (isExactInput) {
            pay(data.tokenIn, address(this), msg.sender, amountToPay);
        } else {
            // swap in/out because exact output swaps are reversed
            data.tokenIn = data.tokenOut;
            pay(data.tokenIn, address(this), msg.sender, amountToPay);
        }

        uint256 profit = amountOutInNextPool - amountToPay;
        uint256 fee = profit * feeRate / FEE_FACTOR;
        IWETH9(WETH).withdraw(profit);

        payable(receiver).transfer(profit - fee);
        payable(feeReceiver).transfer(fee);

        emit FlashProfit(receiver, profit - fee, fee);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WETH && address(this).balance >= value) {
            // pay with WETH9
            IWETH9(WETH).deposit{value: value}(); // wrap only what is needed to pay
            IWETH9(WETH).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            SafeERC20.safeTransfer(IERC20(token), recipient, value);
        } else {
            // pull payment
            SafeERC20.safeTransferFrom(IERC20(token), payer, recipient, value);
        }
    }

    function _checkAndAdjustERC20Allowance(address token, uint256 amount) internal {
        if (IERC20(token).allowance(address(this), address(swapRouter)) < amount) {
            IERC20(token).approve(address(swapRouter), type(uint256).max);
        }
    }
    
    receive() external payable {}
}