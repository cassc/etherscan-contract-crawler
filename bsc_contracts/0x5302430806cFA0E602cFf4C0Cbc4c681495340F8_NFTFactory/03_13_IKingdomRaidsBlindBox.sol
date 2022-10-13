// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKingdomRaidsBlindBox {
    function burn(
        address from,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}