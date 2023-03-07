pragma solidity ^0.8.0;

interface IRandomizer {
    function random(uint256 id, uint256 range, address _address)
        external
        view
        returns (uint256);
}