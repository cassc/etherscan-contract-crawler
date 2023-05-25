pragma solidity 0.8.12;

interface IRevocable {
    function revoke(address to, uint256 tokenId) external returns (bool);
    event Revoked(address from, address to, uint256 tokenId);
}