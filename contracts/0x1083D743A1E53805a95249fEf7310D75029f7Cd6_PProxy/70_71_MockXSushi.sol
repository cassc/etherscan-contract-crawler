// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "./MockToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract MockXSushi is MockToken {
    using SafeMath for uint256;
    uint256 public exchangeRate = 1 ether / 5;
    MockToken public underlying;

    uint256 public errorCode;
    constructor(address _underlying) MockToken("xSUSHI", "xSUSHI") public {
        underlying = MockToken(_underlying);
    }

    function mint(uint256 _amount) external {
        require(underlying.transferFrom(msg.sender, address(this), _amount), "MockXSushi.mint: transferFrom failed");

        uint256 mintAmount = _amount.mul(10**18).div(exchangeRate);
        _mint(msg.sender, mintAmount);
    }

    function enter(uint256 _amount) external {
        require(underlying.transferFrom(msg.sender, address(this), _amount), "MockXSushi.enter: transferFrom failed");

        uint256 mintAmount = _amount.mul(10**18).div(exchangeRate);
        _mint(msg.sender, mintAmount);
    }

    function exchangeRateStored() external view returns(uint256) {
        return exchangeRate;
    }

    function leave(uint256 _amount) external{
        _burn(msg.sender, _amount);

        uint256 underlyingAmount = _amount.mul(exchangeRate).div(10**18);
        underlying.mint(underlyingAmount, msg.sender);
    }
}