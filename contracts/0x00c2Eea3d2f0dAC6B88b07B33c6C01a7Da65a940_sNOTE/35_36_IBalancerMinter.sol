pragma solidity =0.8.11;

interface IBalancerMinter {
    function mint(address gauge) external;
    function getBalancerToken() external returns (address);
}