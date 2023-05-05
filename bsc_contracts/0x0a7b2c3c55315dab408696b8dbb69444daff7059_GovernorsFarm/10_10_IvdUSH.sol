pragma solidity ^0.8.13;

interface IvdUSH {

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);

    function locked(address account) external view returns(uint256);
    function deposit_for(address _addr, uint _valueA, uint _valueB, uint _valueC) external;
    function approve(address spender, uint256 amount) external returns (bool);
}