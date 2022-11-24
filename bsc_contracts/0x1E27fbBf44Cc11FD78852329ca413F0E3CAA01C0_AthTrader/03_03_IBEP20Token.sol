pragma solidity ^0.8.0;

interface IBEP20Token {
    // Transfer tokens on behalf
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    // Transfer tokens
    function transfer(
        address to,
        uint256 value
    ) external returns (bool success);

    // Approve tokens for spending
    function approve(address spender, uint256 amount) external returns (bool);

    // Returns user balance
    function balanceOf(address user) external view returns(uint256 value);

    //Returns token Decimals
    function decimals() external view returns (uint256);
}