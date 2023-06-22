// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract ProxyFee is Ownable {

    using SafeMath for uint;

    uint public feeBase;
    uint public feeMul; // example: feeBase + feeSum = 1001 or 100.1%
    uint public maxFeePercent = 10; // Maximum but not current fee, just for validation

    /// Update fee params event
    /// @param _feeBase uint  Base fee amount
    /// @param _feeMul uint  Multiply fee amount
    event UpdateFeeParams(uint _feeBase, uint _feeMul);

    /// Set system fee (only for owner)
    /// @param _feeBase uint  Base fee
    /// @param _feeMul uint  Multiply fee
    function setFeeParams(uint _feeBase, uint _feeMul) public onlyOwner {
        require(_feeBase > 0, "Fee: _feeBase must be valid");
        require(_feeMul > 0, "Fee: _feeMul must be valid");
        uint validationAmount = 1000;
        require(
            validationAmount.mul(maxFeePercent).div(100) >= calcFeeWithParams(validationAmount, _feeBase, _feeMul),
            "Fee: fee must be less than maximum"
        );

        feeBase = _feeBase;
        feeMul = _feeMul;
        emit UpdateFeeParams(_feeBase, _feeMul);
    }

    /// Calculate fee by amount
    /// @param _amount uint  Amount
    /// @return uint  Calculated fee
    function calcFee(uint _amount) internal view returns(uint) {
        return calcFeeWithParams(_amount, feeBase, feeMul);
    }

    /// Calculate fee with params
    /// @param _amount uint  Amount
    /// @param _feeBase uint  Base fee
    /// @param _feeMul uint  Multiply fee
    /// @return uint  Calculated fee
    function calcFeeWithParams(uint _amount, uint _feeBase, uint _feeMul) internal pure returns(uint) {
        return _amount.mul(_feeMul).div(_feeBase.add(_feeMul));
    }
}