pragma solidity ^0.8.13;

abstract contract ICryptoPunksData {
    function punkImage(uint16 index) public view virtual returns (bytes memory);
}