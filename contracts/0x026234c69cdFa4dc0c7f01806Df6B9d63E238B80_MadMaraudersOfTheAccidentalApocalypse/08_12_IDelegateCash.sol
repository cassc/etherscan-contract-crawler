// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IDelegateCash {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}