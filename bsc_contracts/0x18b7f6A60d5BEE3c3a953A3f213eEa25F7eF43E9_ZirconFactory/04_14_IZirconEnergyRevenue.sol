pragma solidity =0.5.16;

interface IZirconEnergyRevenue {
    function initialize(address _pair, address _tokenA, address _tokenB, address energy0, address energy1, address pylon0, address pylon1) external;
    function calculate(uint percentage) external;
    function migrateLiquidity(address newEnergy) external;
    function getBalanceFromPair() external returns (uint);
    function feeValue1() external returns (uint);
    function feeValue0() external returns (uint);
    function getFees(address _token, uint _amount, address _to) external;
    function setFeeValue(uint _feeValue0, uint _feeValue1) external;
}