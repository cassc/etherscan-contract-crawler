pragma solidity 0.5.15;

interface ICrvDeposit{
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
    // function claimable_tokens(address) external view returns (uint256);
}