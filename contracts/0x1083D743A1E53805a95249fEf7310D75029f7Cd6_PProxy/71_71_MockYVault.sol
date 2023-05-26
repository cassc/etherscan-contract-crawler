// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "./MockToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract MockYVault is MockToken {
    using SafeMath for uint256;
    uint256 public exchangeRate = 1 ether / 5;
    MockToken public underlying;

    constructor(address _underlying) MockToken("yVAULT", "yVAULT") public {
        underlying = MockToken(_underlying);
    }

    function mint(uint256 _amount) external {
        require(underlying.transferFrom(msg.sender, address(this), _amount), "MockXSushi.mint: transferFrom failed");

        uint256 mintAmount = _amount.mul(10**18).div(exchangeRate);
        _mint(msg.sender, mintAmount);
    }

    function deposit(uint256 _amount) external {
        require(underlying.transferFrom(msg.sender, address(this), _amount), "MockYVault.enter: transferFrom failed");

        uint256 mintAmount = _amount.mul(10**18).div(exchangeRate);
        _mint(msg.sender, mintAmount);
    }

    function getPricePerFullShare() external view returns(uint) {
        return exchangeRate;
    }

    function withdraw(uint256 _amount) external{
        _burn(msg.sender, _amount);

        uint256 underlyingAmount = _amount.mul(exchangeRate).div(10**18);
        underlying.mint(underlyingAmount, msg.sender);
    }
}