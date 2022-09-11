pragma solidity 0.8.6;


import "IPriceOracle.sol";


interface IOracle {
    // Needs to output the same number for the whole epoch
    function getRandNum(uint salt) external view returns (uint);

    function getPriceOracle() external view returns (IPriceOracle);

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);

    function setPriceOracle(IPriceOracle newPriceOracle) external;

    function defaultPayIsAUTO() external view returns (bool);

    function setDefaultPayIsAUTO(bool newDefaultPayIsAUTO) external;
}