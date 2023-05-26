pragma solidity ^0.8.13;

interface IMarket {
    function borrowOnBehalf(address msgSender, uint dolaAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function withdrawOnBehalf(address msgSender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function deposit(address msgSender, uint collateralAmount) external;
    function repay(address msgSender, uint amount) external;
    function collateral() external returns(address);
    function debts(address user) external returns(uint);
    function recall(uint amount) external;
    function totalDebt() external view returns (uint);
    function borrowPaused() external view returns (bool);
}