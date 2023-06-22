pragma solidity ^0.8.19;

interface INTStakedToken {

    function give(address to, bytes calldata metadata, bytes calldata) external returns(uint256);

    function burn(uint256 tokenId) external returns (uint256);
}