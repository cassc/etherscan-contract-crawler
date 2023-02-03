// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { ERC20 } from "solmate/tokens/ERC20.sol";

import { BalancerVault } from "./BalancerVault.sol";

interface Space {
    function getPoolId() external view returns (bytes32);
    function totalSupply() external view returns (uint256);
    function pti() external view returns (uint256);
    function ts() external view returns (uint256);
    function g2() external view returns (uint256);
    
    struct SwapRequest {
        BalancerVault.SwapKind kind;
        ERC20 tokenIn;
        ERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) 
    external 
    view // This is a lie. But it indeed will only mutate storage if called by the Balancer Vault, so it's true for our purposes here.
    returns (uint256);

    function balanceOf(address user) external view returns (uint256 amount);
    function getPriceFromImpliedRate(uint256 impliedRate) external view returns (uint256 pTPriceInTarget);
    function adjustedTotalSupply() external view returns (uint256 supply);
    
    function getEQReserves(
        uint256 stretchedRate,
        uint256 maturity,
        uint256 ptReserves,
        uint256 targetReserves,
        uint256 totalSupply,
        uint256 initScale
    ) external view returns (
        uint256 eqPTReserves,
        uint256 eqTargetReserves
    );

    function onSwapPreview(
        bool ptIn,
        bool givenIn,
        uint256 amountDelta,
        uint256 reservesTokenIn,
        uint256 reservesTokenOut,
        uint256 totalSupply,
        uint256 scale
    ) external view returns (uint256);
}