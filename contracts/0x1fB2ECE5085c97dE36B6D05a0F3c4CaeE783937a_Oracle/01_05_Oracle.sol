pragma solidity 0.8.6;


import "Ownable.sol";
import "IOracle.sol";
import "IPriceOracle.sol";


contract Oracle is IOracle, Ownable {

    IPriceOracle private _priceOracle;
    bool private _defaultPayIsAUTO;


    constructor(IPriceOracle priceOracle, bool defaultPayIsAUTO) Ownable() {
        _priceOracle = priceOracle;
        _defaultPayIsAUTO = defaultPayIsAUTO;
    }


    function getRandNum(uint seed) external override view returns (uint) {
        return uint(blockhash(seed));
    }

    function getPriceOracle() external override view returns (IPriceOracle) {
        return _priceOracle;
    }

    function getAUTOPerETH() external override view returns (uint) {
        return _priceOracle.getAUTOPerETH();
    }

    function getGasPriceFast() external override view returns (uint) {
        return _priceOracle.getGasPriceFast();
    }

    function setPriceOracle(IPriceOracle newPriceOracle) external override onlyOwner {
        _priceOracle = newPriceOracle;
    }

    function defaultPayIsAUTO() external override view returns (bool) {
        return _defaultPayIsAUTO;
    }

    function setDefaultPayIsAUTO(bool newDefaultPayIsAUTO) external override onlyOwner {
        _defaultPayIsAUTO = newDefaultPayIsAUTO;
    }
}