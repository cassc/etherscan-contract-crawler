pragma solidity 0.8.6;


import "Ownable.sol";
import "IPriceOracle.sol";


contract PriceOracle is IPriceOracle, Ownable {


    uint private _AUTOPerETH;
    uint private _gasPrice;


    constructor(uint AUTOPerETH, uint gasPrice) Ownable() {
        _AUTOPerETH = AUTOPerETH;
        _gasPrice = gasPrice;
    }

    function getAUTOPerETH() external override view returns (uint) {
        return _AUTOPerETH;
    }

    function updateAUTOPerETH(uint AUTOPerETH) external onlyOwner {
        _AUTOPerETH = AUTOPerETH;
    }

    function getGasPriceFast() external override view returns (uint) {
        return _gasPrice;
    }

    function updateGasPriceFast(uint gasPrice) external onlyOwner {
        _gasPrice = gasPrice;
    }
}