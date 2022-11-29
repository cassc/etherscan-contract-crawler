// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProxyUtils.sol";

abstract contract ProxyFee is Ownable {

    uint internal feeBase = 1000;
    uint internal feeMul = 1; // feeBase + feeSum = 1001 or 100.1%

    /**
     * Set system fee
     */
    function setFeeBase(uint _feeBase) public onlyOwner {
        require(_feeBase > 0, "Fee: feeBase must be valid");

        feeBase = _feeBase;
    }

    /**
     * Set system fee
     */
    function setFeeMul(uint _feeMul) public onlyOwner {
        require(_feeMul > 0, "Fee: feeMul must be valid");

        feeMul = _feeMul;
    }

    /**
     * Return base fee param
     */
    function getFeeBase() public view returns(uint) {
        return feeBase;
    }

    /**
     * Return fee multiply
     */
    function getFeeMul() public view returns(uint) {
        return feeMul;
    }

    /**
     * Calculate amount (sub fee)
     */
    function calcAmount(uint amount) internal view returns(uint) {
        return amount - calcFee(amount);
    }

    /**
     * Calculate fee
     */
    function calcFee(uint amount) internal view returns(uint) {
        return amount * feeMul / (feeBase + feeMul);
    }
}