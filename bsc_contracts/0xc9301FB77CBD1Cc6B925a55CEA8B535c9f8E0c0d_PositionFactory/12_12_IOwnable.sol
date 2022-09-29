pragma solidity ^0.8.17;
interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address newOwner) external;
}