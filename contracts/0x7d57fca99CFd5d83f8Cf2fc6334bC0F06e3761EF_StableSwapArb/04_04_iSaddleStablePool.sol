pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "solmate/tokens/ERC20.sol";
//import "./IAllowlist.sol";

interface iSaddleStablePool {
    // pool data view functions
    function getA() external view returns (uint256);

//    function getAllowlist() external view returns (IAllowlist);

    function getToken(uint8 index) external view returns (ERC20);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function isGuarded() external view returns (bool);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
    external
    view
    returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
    external
    view
    returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    // state modifying functions
    function initialize(
        ERC20[] memory pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 a,
        uint256 fee,
        uint256 adminFee,
        address lpTokenTargetAddress
    ) external;

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event NewAdminFee(uint256 newAdminFee);
    event NewSwapFee(uint256 newSwapFee);
    event NewWithdrawFee(uint256 newWithdrawFee);
}