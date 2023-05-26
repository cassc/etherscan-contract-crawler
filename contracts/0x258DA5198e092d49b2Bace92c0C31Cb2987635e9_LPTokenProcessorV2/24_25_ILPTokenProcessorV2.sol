// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ILPTokenProcessorV2 {
    struct TokenSwapInfo {
        address tokenAddress;
        address routerFactory;
        bool isV2;
        address referrer;
        address vault;
        uint256 amount;
    }

    function addTokenForSwapping(TokenSwapInfo memory params) external;

    function getRouter(address lpTokenAddress) external view returns (address);

    function getV3Position(address tokenAddress, uint256 tokenId)
        external
        view
        returns (
            address,
            address,
            uint128
        );

    function isV2LiquidityPoolToken(address tokenAddress) external view returns (bool);

    function isV3LiquidityPoolToken(address tokenAddress, uint256 tokenId) external view returns (bool);

    function swapTokens(
        address sourceToken,
        uint256 sourceAmount,
        address destinationToken,
        address receiver,
        address routerAddress
    ) external returns (bool);
}