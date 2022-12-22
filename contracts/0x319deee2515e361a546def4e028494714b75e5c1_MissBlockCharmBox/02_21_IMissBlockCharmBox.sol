//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMissBlockCharmBox {
    event BoxCreated(uint256 boxId, address owner);
    event BoxOpened(uint256 boxId);
    event TokenWithdrawn(address token, uint256 amount, address to);

    struct Seller {
        uint256 maxSupply;
        uint256 minted;
    }

    function mint(uint256 amount, address buyer) external payable;
}