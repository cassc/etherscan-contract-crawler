pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IBalancerVault.sol";

interface IBalancerWrapper {
    struct Asset {
        address token;
        bytes queryIn;
        bytes queryOut;
    }

    function swapSingle(
        address tokenOut,
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes32 poolId,
        uint256 deadline
    ) external returns (uint256);

    function join(
        uint256[] memory amounts,
        bytes32 poolId,
        address WANT,
        Asset[] memory assets,
        IBalancerVault.JoinKind joinKind
    ) external returns (uint256);

    function exit(
        uint256 amount,
        uint256[] memory minAmountsOut,
        bytes32 poolId,
        address WANT,
        Asset[] memory assets,
        IBalancerVault.ExitKind exitKind
    ) external returns (uint256[] memory);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        bytes32 poolId
    ) external returns (uint256);
}