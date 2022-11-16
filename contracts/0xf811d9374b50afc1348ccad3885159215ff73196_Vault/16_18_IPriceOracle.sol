// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPriceOracle {
    function getPrice(
        address token,
        uint256 tokenId,
        uint256 maxAge,
        bytes calldata offChainData
    ) external view returns (uint256 price);
}