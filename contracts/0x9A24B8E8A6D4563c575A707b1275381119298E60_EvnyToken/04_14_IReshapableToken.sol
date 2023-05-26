pragma solidity >=0.6.0 <0.8.0;

interface IReshapableToken {
    function deposit(address token, uint256 amount) external returns(uint256);
}