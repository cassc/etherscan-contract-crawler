pragma solidity 0.7.6;

interface ISwapContract {
    function getActiveNodes() external returns (address[] memory);

    function isNodeStake(address _user) external returns (bool);

    function lpToken() external returns (address);
}