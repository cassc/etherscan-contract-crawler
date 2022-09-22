pragma solidity ^0.8.4;

interface IBase {
    function nameExpires(uint256) external view returns(uint);
    function ownerOf(uint256) external view returns(address);
}