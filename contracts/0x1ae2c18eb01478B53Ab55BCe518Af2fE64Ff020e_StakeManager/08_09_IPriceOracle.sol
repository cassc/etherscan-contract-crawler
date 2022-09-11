pragma solidity 0.8.6;


interface IPriceOracle {

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);
}