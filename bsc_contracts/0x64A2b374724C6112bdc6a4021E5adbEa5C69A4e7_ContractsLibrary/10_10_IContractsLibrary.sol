// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../IUniswapV2Router01.sol";

abstract contract IContractsLibrary {
    function BUSD() external view virtual returns (address);

    function WBNB() external view virtual returns (address);

    function ROUTER() external view virtual returns (IUniswapV2Router01);

    function getBusdToBNBToToken(
        address token,
        uint _amount
    ) external view virtual returns (uint256);

    function getTokensToBNBtoBusd(
        address token,
        uint _amount
    ) external view virtual returns (uint256);

    function getTokensToBnb(
        address token,
        uint _amount
    ) external view virtual returns (uint256);

    function getBnbToTokens(
        address token,
        uint _amount
    ) public view virtual returns (uint256);

    function getTokenToBnbToAltToken(
        address token,
        address altToken,
        uint _amount
    ) public view virtual returns (uint256);
}