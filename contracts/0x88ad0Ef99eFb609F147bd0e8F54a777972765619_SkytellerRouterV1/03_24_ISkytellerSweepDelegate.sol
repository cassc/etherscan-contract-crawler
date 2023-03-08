// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISkytellerSweepDelegate {
    /// @notice Sweep to the destination address, converting from tokenIn to tokenOut
    /// @dev Caller must transfer amountIn to the contract before calling this function.
    ///      Only supported ERC-20s. ETH->WETH wrapping should be done by the caller.
    /// @param tokenIn The token to sweep from the contract
    /// @param tokenOut The token to sweep to the destination address
    /// @param amountIn The amount of token to sweep
    /// @param destination The address to sweep the tokens to
    /// @return amountOut The amount of tokenOut swept
    function sweep(IERC20 tokenIn, IERC20 tokenOut, uint256 amountIn, address destination)
        external
        returns (uint256 amountOut);
}