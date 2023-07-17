pragma solidity >=0.8.0;

import "./IAavePriceOracle.sol";

interface IAavePoolAddressesProvider {
    function getPriceOracle() external view returns (IAavePriceOracle);
}