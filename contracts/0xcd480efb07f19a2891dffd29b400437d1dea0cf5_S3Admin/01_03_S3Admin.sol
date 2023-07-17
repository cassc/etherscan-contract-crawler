// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Ownable.sol";


contract S3Admin is Ownable { 
    address public aave;
    address public aaveEth;
    address public aavePriceOracle;
    address public aWETH;
    uint8 public slippage = 1;
    mapping(uint8 => address) public interestTokens;
    mapping(uint8 => bool) public whitelistedAaveBorrowPercAmounts;

    constructor(
        address _aave,
        address _aaveEth,
        address _aavePriceOracle,
        address _aWETH
    ) {
        aave = _aave;
        aaveEth = _aaveEth;
        aavePriceOracle = _aavePriceOracle;
        aWETH = _aWETH;
    }

    function setSlippage(uint8 _slippage) external onlyOwner {
        slippage = _slippage;
    }

    function setInterestTokens(uint8 _strategyIndex, address _address) external onlyOwner {
        interestTokens[_strategyIndex] = _address;
    }

    function setAaveBorrowPercAmounts(uint8 _amount, bool _bool) external onlyOwner {
        whitelistedAaveBorrowPercAmounts[_amount] = _bool;  
    }
}

// MN bby ¯\_(ツ)_/¯