pragma solidity ^0.8.0;


interface community_interface {

    function community_claimed(address) external view returns (uint256);

    function communityPurchase(address recipient, uint256 tokenCount, bytes memory signature, uint256 role) external payable;

}