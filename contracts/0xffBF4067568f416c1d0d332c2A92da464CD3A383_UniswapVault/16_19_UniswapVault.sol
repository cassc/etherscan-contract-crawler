// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import { SafeERC20Upgradeable, IERC20Upgradeable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IUniswapV2Router02 } from "../../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "../../../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "../../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import { Vault } from "../Vault.sol";
import { UniswapVaultStorage } from "./UniswapVaultStorage.sol";

/// @notice Contains the primary logic for Uniswap Vaults
/// @author Recursive Research Inc
contract UniswapVault is Vault, UniswapVaultStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
        address coreAddress,
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum,
        address _uniswapFactory,
        address _uniswapRouter
    ) public virtual initializer {
        __UniswapVault_init(
            coreAddress,
            _epochDuration,
            _token0,
            _token1,
            _token0FloorNum,
            _token1FloorNum,
            _uniswapFactory,
            _uniswapRouter
        );
    }

    function __UniswapVault_init(
        address coreAddress,
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum,
        address _uniswapFactory,
        address _uniswapRouter
    ) internal onlyInitializing {
        __Vault_init(coreAddress, _epochDuration, _token0, _token1, _token0FloorNum, _token1FloorNum);
        __UniswapVault_init_unchained(_uniswapFactory, _uniswapRouter);
    }

    function __UniswapVault_init_unchained(address _uniswapFactory, address _uniswapRouter) internal onlyInitializing {
        pair = IUniswapV2Factory(_uniswapFactory).getPair(address(token0), address(token1));

        // require that the pair has been created
        require(pair != address(0), "ZERO_ADDRESS");

        factory = _uniswapFactory;
        router = _uniswapRouter;
    }

    // @dev queries the pool reserves and ensure the token ordering is correct
    function getPoolBalances() internal view virtual override returns (uint256, uint256) {
        (uint256 reservesA, uint256 reservesB, ) = IUniswapV2Pair(pair).getReserves();
        return IUniswapV2Pair(pair).token0() == address(token0) ? (reservesA, reservesB) : (reservesB, reservesA);
    }

    // This is provided automatically by the Uniswap router
    function calcAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view virtual override returns (uint256) {
        return IUniswapV2Router02(router).getAmountIn(amountOut, reserveIn, reserveOut);
    }

    // Withdraws all liquidity
    // @dev We can ignore the need for frontrunning checks because the `_nextEpoch` function checks
    // that the pool reserves are as expected beforehand
    function _withdrawLiquidity() internal virtual override {
        uint256 lpTokenBalance = IERC20Upgradeable(pair).balanceOf(address(this));
        if (lpTokenBalance == 0) return;

        // use the router to remove liquidity from the uni pool
        // don't need to decrease allowance afterwards because router guarantees the full amount is burned
        // safe to ignore return values because we check balances before and after this call
        IERC20Upgradeable(pair).safeIncreaseAllowance(router, lpTokenBalance);
        IUniswapV2Router02(router).removeLiquidity(
            address(token0),
            address(token1),
            lpTokenBalance,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    // Deposits available liquidity
    // @dev We can ignore the need for frontrunning checks because the `_nextEpoch` function checks
    // that the pool reserves are as expected beforehand
    // `availableToken0` and `availableToken1` are also known to be greater than 0 since they are checked
    // by `depositLiquidity` in `Vault.sol`
    function _depositLiquidity(uint256 availableToken0, uint256 availableToken1)
        internal
        virtual
        override
        returns (uint256 token0Deposited, uint256 token1Deposited)
    {
        // use the router to deposit `token0` and `token1`
        token0.safeIncreaseAllowance(router, availableToken0);
        token1.safeIncreaseAllowance(router, availableToken1);
        // can safely ignore `liquidity` return value because when withdrawing we check our full balance
        (token0Deposited, token1Deposited, ) = IUniswapV2Router02(router).addLiquidity(
            address(token0),
            address(token1),
            availableToken0,
            availableToken1,
            0,
            0,
            address(this),
            block.timestamp
        );

        // if we didn't deposit the full `availableToken{x}`, reduce allowance for safety
        if (availableToken0 > token0Deposited) {
            token0.safeApprove(router, 0);
        }
        if (availableToken1 > token1Deposited) {
            token1.safeApprove(router, 0);
        }
    }

    // For the default Uniswap vault this does nothing
    function _unstakeLiquidity() internal virtual override {}

    // For the default Uniswap vault this does nothing
    function _stakeLiquidity() internal virtual override {}

    // Swaps tokens
    // @dev We can ignore the need for frontrunning checks because the `_nextEpoch` function checks
    // that the pool reserves are as expected beforehand
    function swap(
        IERC20Upgradeable tokenIn,
        IERC20Upgradeable tokenOut,
        uint256 amountIn
    ) internal virtual override returns (uint256 amountOut, uint256 amountConsumed) {
        if (amountIn == 0) return (0, 0);

        tokenIn.safeIncreaseAllowance(router, amountIn);
        amountOut = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn,
            0,
            getPath(address(tokenIn), address(tokenOut)),
            address(this),
            block.timestamp
        )[1];
        amountConsumed = amountIn;
    }

    /// @notice converts two addresses into an address[] type
    function getPath(address _from, address _to) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
    }
}