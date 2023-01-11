// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ITransferCallbackContract {

    function beforeTransferCallback(address from, address to, uint256 tokenId) external;
    function afterTransferCallback(address from, address to, uint256 tokenId) external;

}