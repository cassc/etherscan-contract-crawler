// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../interfaces/IPoolInteractor.sol";
import "../interfaces/UniswapV2/IUniswapV2Pair.sol";
import "../libraries/Math.sol";

contract UniswapV2PoolInteractor is IPoolInteractor {
    using SaferERC20 for IERC20;

    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

    function burn(
        address lpTokenAddress,
        uint256 amount,
        address self
    ) external payable returns (address[] memory, uint256[] memory) {
        IUniswapV2Pair pair = IUniswapV2Pair(lpTokenAddress);
        address[] memory receivedTokens = new address[](2);
        receivedTokens[0] = pair.token0();
        receivedTokens[1] = pair.token1();
        uint256[] memory receivedTokenAmounts = new uint256[](2);
        if (amount == 0) {
            receivedTokenAmounts[0] = 0;
            receivedTokenAmounts[1] = 0;
        } else {
            pair.transfer(lpTokenAddress, amount);
            (uint256 amount0, uint256 amount1) = pair.burn(address(this));
            receivedTokenAmounts[0] = amount0;
            receivedTokenAmounts[1] = amount1;
            emit Burn(lpTokenAddress, amount);
        }
        return (receivedTokens, receivedTokenAmounts);
    }

    function mint(
        address toMint,
        address[] memory underlyingTokens,
        uint256[] memory underlyingAmounts,
        address receiver,
        address self
    ) external payable returns (uint256) {
        IUniswapV2Pair poolContract = IUniswapV2Pair(toMint);
        if (underlyingAmounts[0] + underlyingAmounts[1] == 0) {
            return 0;
        }
        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            IERC20(underlyingTokens[i]).safeTransfer(toMint, underlyingAmounts[i]);
        }
        uint256 minted = poolContract.mint(receiver);
        return minted;
    }

    function simulateMint(
        address toMint,
        address[] memory underlyingTokens,
        uint256[] memory underlyingAmounts
    ) external view returns (uint256 minted) {
        IUniswapV2Pair pair = IUniswapV2Pair(toMint);
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        uint256 amount0;
        uint256 amount1;
        if (underlyingTokens[0] == pair.token0()) {
            amount0 = underlyingAmounts[0];
            amount1 = underlyingAmounts[1];
        } else {
            amount0 = underlyingAmounts[1];
            amount1 = underlyingAmounts[0];
        }
        if (totalSupply == 0) {
            minted = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
        } else {
            minted = Math.min((amount0 * totalSupply) / r0, (amount1 * totalSupply) / r1);
        }
    }

    function testSupported(address token) external view override returns (bool) {
        try IUniswapV2Pair(token).token0() returns (address) {} catch {
            return false;
        }
        try IUniswapV2Pair(token).token1() returns (address) {} catch {
            return false;
        }
        try IUniswapV2Pair(token).getReserves() returns (uint112, uint112, uint32) {} catch {
            return false;
        }
        try IUniswapV2Pair(token).kLast() returns (uint256) {} catch {
            return false;
        }
        return true;
    }

    function getUnderlyingAmount(
        address lpTokenAddress,
        uint256 amount
    ) external view returns (address[] memory underlying, uint256[] memory amounts) {
        IUniswapV2Pair lpToken = IUniswapV2Pair(lpTokenAddress);
        (uint256 r0, uint256 r1, ) = lpToken.getReserves();
        uint256 supply = lpToken.totalSupply();
        (underlying, ) = getUnderlyingTokens(lpTokenAddress);
        amounts = new uint256[](2);
        amounts[0] = (amount * r0) / supply;
        amounts[1] = (amount * r1) / supply;
    }

    function getUnderlyingTokens(address lpTokenAddress) public view returns (address[] memory, uint256[] memory) {
        IUniswapV2Pair poolContract = IUniswapV2Pair(lpTokenAddress);
        address[] memory receivedTokens = new address[](2);
        receivedTokens[0] = poolContract.token0();
        receivedTokens[1] = poolContract.token1();
        uint256[] memory ratios = new uint256[](2);
        ratios[0] = 1;
        ratios[1] = 1;
        return (receivedTokens, ratios);
    }
}