// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISweeper {
    function sweep(address _collection, uint256 _tokenId, uint256 _price, bytes calldata _data, address _to) external;
}