// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import {IFeeRateModel} from "../intf/IFeeRateModel.sol";
import "../DODOV3MM/lib/InitializableOwnable.sol";

contract MockFeeRateModel is IFeeRateModel, InitializableOwnable {
    mapping(address => bool) public isUsedFeeRate;
    mapping(address => uint256) public feeRateMap;
    uint256 public defaultFeeRate; 

    function init(address owner, uint256 _feeRate) public {
        initOwner(owner);
        defaultFeeRate = _feeRate;
    }

    function setDefaultFeeRate(uint256 newFeeRate) public onlyOwner {
        defaultFeeRate = newFeeRate;
    }

    function setIsUseFeeRate(address token, bool isUse) public onlyOwner {
        isUsedFeeRate[token] = isUse;
    }

    function setTokenFeeRate(address token, uint256 tokenFeeRate) public onlyOwner {
        feeRateMap[token] = tokenFeeRate;
    }

    function getFeeRate(address token) external view returns(uint256 feerate) {
        return isUsedFeeRate[token] ? feeRateMap[token] : defaultFeeRate;
    }

    function testSuccess() public {}
}