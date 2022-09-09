// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

// Buy with native token
interface ICedarNativePayableV0 {

    function buy(
        uint256 quantity,
        address recipient,
        uint256 tokenId
    ) external payable;
}