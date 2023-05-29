// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

/// @notice IExchangeManager is a generalized interface for all the liquidity managers
/// @dev Contains all necessary methods that should be available in liquidity manager contracts
interface IExchangeManager {
    struct DepositParams {
        address recipient;
        address exchangeManagerAddress;
        address token0;
        address token1;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 tokenId;
    }

    struct WithdrawParams {
        bool pilotToken;
        bool wethToken;
        address exchangeManagerAddress;
        uint256 liquidity;
        uint256 tokenId;
    }

    struct CollectParams {
        bool pilotToken;
        bool wethToken;
        address exchangeManagerAddress;
        uint256 tokenId;
    }

    function createPair(
        address _token0,
        address _token1,
        bytes calldata data
    ) external;

    function deposit(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 shares,
        uint256 tokenId,
        bool isTokenMinted,
        bytes calldata data
    ) external payable;

    function withdraw(
        bool pilotToken,
        bool wethToken,
        uint256 liquidity,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function getReserves(
        address token0,
        address token1,
        bytes calldata data
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );

    function collect(
        bool pilotToken,
        bool wethToken,
        uint256 tokenId,
        bytes calldata data
    ) external payable;
}