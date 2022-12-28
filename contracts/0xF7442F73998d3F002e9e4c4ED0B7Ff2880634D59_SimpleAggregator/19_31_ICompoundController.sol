//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "./IPriceOracle.sol";

interface ICompoundController {
    function oracle() external view returns (IPriceOracle);

    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function checkMembership(address account, address cToken) external view returns (bool);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint,
            uint,
            uint
        );

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint transferTokens
    ) external returns (uint);

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint redeemTokens
    ) external returns (uint);
}