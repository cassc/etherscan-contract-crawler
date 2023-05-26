// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract ILevels {

    address public honeyContract;

    function consumeToken(address _collectionAddress, uint256 _collectionTokenId, address _tokenAddress, uint256 _amount) public virtual;
    function consumeETH(address _collectionAddress, uint256 _collectionTokenId, uint256 _amount) public virtual;
    function getConsumedToken(address _collectionAddress, uint256 _collectionTokenId, address _tokenAddress) public virtual returns (uint256);
    function getConsumedETH(address _collectionAddress, uint256 _collectionTokenId) public virtual returns (uint256);
    
}