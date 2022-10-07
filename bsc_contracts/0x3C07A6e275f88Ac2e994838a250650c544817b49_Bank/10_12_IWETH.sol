pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address _address) external returns (uint256);
    function withdraw(uint256) external;
    function approve(address spender, uint256 amount) external returns (bool);
}