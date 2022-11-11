// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IERC721MultiSaleMultiWallet {
    function getBuyCount(uint256 userId) external view returns(uint256);
}