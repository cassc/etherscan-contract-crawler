pragma solidity ^0.8.13;

interface IMarketplace {

    function isActiveAuction(uint256 _tokenId) external view returns (bool);

}