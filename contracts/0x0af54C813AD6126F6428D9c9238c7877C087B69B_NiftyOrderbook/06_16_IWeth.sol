pragma solidity ^0.8.4;

interface IWeth {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function withdraw(uint wad) external;
}