// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IThorchainRouter {
    function depositWithExpiry(
        address payable vault,
        address asset,
        uint256 amount,
        string memory memo,
        uint256 expiration
    ) external payable;
}