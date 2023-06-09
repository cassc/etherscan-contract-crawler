pragma solidity ^0.8.0;

interface IProxySale {
    function isStake(uint256 _tokenId) external view returns (bool);
}