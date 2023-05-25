pragma solidity ^0.5.16;

interface IINV {
    function balanceOf(address) external view returns (uint);
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
    function allowance(address,address) external view returns (uint);
    function delegates(address) external view returns (address);
    function delegate(address) external;
}