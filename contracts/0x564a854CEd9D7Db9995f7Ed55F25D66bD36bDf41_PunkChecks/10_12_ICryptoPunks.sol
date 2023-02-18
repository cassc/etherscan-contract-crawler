pragma solidity ^0.8.13;

abstract contract ICryptoPunks {
    function punkIndexToAddress(uint256 id) external view virtual returns (address);
}