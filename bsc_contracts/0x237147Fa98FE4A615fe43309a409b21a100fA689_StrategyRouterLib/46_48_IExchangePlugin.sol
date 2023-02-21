//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// import "hardhat/console.sol";

interface IExchangePlugin {
    
    function swap(
        uint256 amountA,
        address tokenA,
        address tokenB,
        address to
    ) external returns (uint256 amountReceivedTokenB);

    /// @notice Returns percent taken by DEX on which we swap provided tokens.
    /// @dev Fee percent has 18 decimals, e.g. 100% = 10**18
    function getExchangeProtocolFee(address tokenA, address tokenB)
        external
        view
        returns (uint256 feePercent);

    /// @notice Synonym of the uniswapV2's function, estimates amount you receive after swap.
    function getAmountOut(uint256 amountA, address tokenA, address tokenB)
        external
        view
        returns (uint256 amountOut);
}