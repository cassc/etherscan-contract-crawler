pragma solidity =0.8.13;

interface CErc20 {
    function mint(uint256 amount) external returns (uint256);

    function underlying() external returns (address);
}