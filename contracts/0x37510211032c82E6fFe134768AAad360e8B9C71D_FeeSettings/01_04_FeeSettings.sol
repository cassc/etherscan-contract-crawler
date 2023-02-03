// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../lib/ownable/Ownable.sol';
import './IFeeSettings.sol';

contract FeeSettings is IFeeSettings, Ownable {
    address _feeAddress;
    uint256 _feePercent = 300; // 0.3%
    uint256 constant _maxFeePercent = 1000; // max fee is 1%
    uint256 _feeEth = 1e16;
    uint256 constant _maxFeeEth = 35e15; // max fixed eth fee is 0.035 eth

    constructor() {
        _feeAddress = msg.sender;
    }

    function feeAddress() external view returns (address) {
        return _feeAddress;
    }

    function feePercent() external view returns (uint256) {
        return _feePercent;
    }

    function feeDecimals() external pure returns(uint256){
        return 100000;
    }

    function feeEth() external view returns (uint256) {
        return _feeEth;
    }

    function setFeeAddress(address newFeeAddress) public onlyOwner {
        _feeAddress = newFeeAddress;
    }

    function setFeePercent(uint256 newFeePercent) external onlyOwner {
        require(newFeePercent >= 0 && newFeePercent <= _maxFeePercent);
        _feePercent = newFeePercent;
    }

    function setFeeEth(uint256 newFeeEth) external onlyOwner {
        require(newFeeEth >= 0 && newFeeEth <= _maxFeeEth);
        _feeEth = newFeeEth;
    }
}