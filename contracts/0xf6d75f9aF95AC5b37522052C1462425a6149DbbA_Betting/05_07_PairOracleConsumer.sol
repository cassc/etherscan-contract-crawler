pragma solidity ^0.6.0;

interface PairOracleConsumer {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function update() external view returns (int);
    function consult(address, uint) external view returns (uint);
}