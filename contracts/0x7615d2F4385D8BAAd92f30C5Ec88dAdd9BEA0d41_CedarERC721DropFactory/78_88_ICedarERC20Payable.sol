// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

// Buy with erc20Token - requires msg.sender to have approved the implementing
// contract for the purchase price
interface ICedarERC20PayableV0 {
    function buy(
        address recipient,
        address erc20TokenContract,
        uint256 tokenId
    ) external;

    function buyAny(
        address recipient,
        address erc20TokenContract,
        uint256 quantity
    ) external;
}