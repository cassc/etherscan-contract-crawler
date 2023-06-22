// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

interface IOddworxStaking {
    function buyItem(uint itemSKU, uint amount, address nftContract, uint[] calldata nftIds, address user) external;
}