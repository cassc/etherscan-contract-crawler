// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "./MockToken.sol";
import "../interfaces/ICToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract MockCToken is MockToken, ICToken {
    using SafeMath for uint256;
    // representable value taken from cEth
    uint256 public exchangeRate = 1 ether / 5;
    MockToken public underlying;
    uint256 someValue;

    uint256 public errorCode;
    constructor(address _underlying) MockToken("cTOKEN", "cToken") public {
        underlying = MockToken(_underlying);
    }

    function mint(uint256 _amount) external override returns(uint256) {
        require(underlying.transferFrom(msg.sender, address(this), _amount), "MockCToken.mint: transferFrom failed");

        uint256 mintAmount = _amount.mul(10**18).div(exchangeRate);
        _mint(msg.sender, mintAmount);

        return errorCode;
    }

    function redeem(uint256 _amount) external override returns(uint256) {
        _burn(msg.sender, _amount);

        uint256 underlyingAmount = _amount.mul(exchangeRate).div(10**18);
        underlying.mint(underlyingAmount, msg.sender);

        return errorCode;
    }

    function redeemUnderlying(uint256 _amount) external returns(uint256) {
        uint256 internalAmount = _amount.mul(10**18).div(exchangeRate);
        _burn(msg.sender, internalAmount);

        underlying.mint(_amount, msg.sender);

        return errorCode;
    }

    function balanceOfUnderlying(address _owner) external returns(uint256) {
        return balanceOf(_owner).mul(exchangeRate).div(10**18);
    }

    function setErrorCode(uint256 _value) public {
        errorCode = _value;
    }

    function supplyRatePerBlock() external override view returns (uint256) {
        return 20000000000;
    }

    function exchangeRateCurrent() external override returns(uint256) {
        // To make function state changing
        someValue ++;
        return exchangeRate;
    }

    function exchangeRateStored() external override view returns(uint256) {
        // To make function non pure;
        someValue;
        return exchangeRate;
    }
}