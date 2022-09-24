// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IBonfireMetaRouter {
    function tracker() external returns (address);

    function wrapper() external returns (address);

    function paths() external returns (address);

    function accumulator() external returns (address);

    function accumulate(address token, uint256 tokenThreshold) external;

    function transferToken(
        address token,
        address to,
        uint256 amount,
        uint256 bonusThreshold
    ) external;

    function swapToken(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline,
        address to,
        address bonusToken,
        uint256 bonusThreshold
    ) external returns (uint256 amountB);

    function buyToken(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 minAmountOut,
        uint256 deadline,
        address to,
        address bonusToken,
        uint256 bonusThreshold
    ) external payable returns (uint256 amountB);

    function sellToken(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline,
        address to,
        address bonusToken,
        uint256 bonusThreshold
    ) external returns (uint256 amountB);

    function simpleQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to
    )
        external
        view
        returns (
            uint256 amountOut,
            address[] memory poolPath,
            address[] memory tokenPath,
            bytes32[] memory poolDescriptions,
            address bonusToken,
            uint256 bonusThreshold,
            uint256 bonusAmount,
            string memory message
        );

    function getBonusParameters(address[] calldata tokenPath)
        external
        view
        returns (
            address bonusToken,
            uint256 bonusThreshold,
            uint256 bonusAmount
        );

    function quote(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amount,
        address to
    ) external view returns (uint256 amountOut);
}