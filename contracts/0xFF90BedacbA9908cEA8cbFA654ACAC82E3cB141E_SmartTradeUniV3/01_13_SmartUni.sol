// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SmartTradeUniV3 is IUniswapV3SwapCallback, Pausable, Ownable {
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    event SwapInfo(int256, int256);

    modifier NoDelegateCall() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _ ;
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    struct transactionWorth {
        uint256 profit;
        uint256 transactionCost;
    }

    function masterSwap(
        address poolAddress,
        bool zeroForOne,
        int256 amountIn,
        uint160 sqrtPriceLimitX96,
        uint256 blockHeightRequired,
        int256 priceToken0Usd,
        int256 priceToken1Usd,
        uint256 ethPriceUsd,
        uint256 minPrUsd
    ) external NoDelegateCall whenNotPaused returns (int256 amount0, int256 amount1) {
        uint256 startGas = gasleft();
        require(block.number <= blockHeightRequired, "Transaction too old");
        require(amountIn > 0, "Amount to swap has to be larger than zero");
        require(sqrtPriceLimitX96 > MIN_SQRT_RATIO && sqrtPriceLimitX96 < MAX_SQRT_RATIO, "SqrtPriceLimitX96 not in range");

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);

        (amount0, amount1) = pool.swap(msg.sender,
            zeroForOne,
            amountIn,
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1) : sqrtPriceLimitX96,
            abi.encode(msg.sender, zeroForOne)
        );

        transactionWorth memory isTransactionWorthIt; 

        isTransactionWorthIt.profit = uint256(amount0 * priceToken0Usd + amount1 * priceToken1Usd);
        isTransactionWorthIt.transactionCost = (startGas - gasleft()) * tx.gasprice * ethPriceUsd;
        require(isTransactionWorthIt.profit > isTransactionWorthIt.transactionCost, "Profit less then transaction cost");
        require(isTransactionWorthIt.profit > minPrUsd, "Too little profit");
        emit SwapInfo(amount0, amount1);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        IUniswapV3Pool pool = IUniswapV3Pool(msg.sender);
        (address payer, bool zeroForOne) = abi.decode(data, (address, bool));

        if(zeroForOne)
        {
            IERC20(pool.token0()).transferFrom(payer, msg.sender, uint256(amount0Delta));
        }
        else
        {
            IERC20(pool.token1()).transferFrom(payer, msg.sender, uint256(amount1Delta));   
        }
    }
}