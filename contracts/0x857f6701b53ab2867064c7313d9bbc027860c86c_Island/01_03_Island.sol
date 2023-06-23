// SPDX-License-Identifier: None
pragma solidity 0.8.20;
import "IERC20.sol";
import "IUniswapV2Pair.sol";

// https://lostcoin.vip

contract Island {
    uint256 public countdown;
    address public lostAddress;
    address public poolAddress;

    event SystemFailure(uint256 amountToSend);
    event CodeEntered();

    constructor(address _lostAddress, address _poolAddress) {
        lostAddress = _lostAddress;
        poolAddress = _poolAddress;
        countdown = block.timestamp + 18 hours;
    }

    function systemFailure() external {
        require(block.timestamp > countdown, "time");

        countdown = block.timestamp + 18 hours;
        uint256 amountToSend = (IERC20(lostAddress).balanceOf(poolAddress) * 10) / 100;
        IERC20(lostAddress).transfer(poolAddress, amountToSend);
        IUniswapV2Pair(poolAddress).sync();
        emit SystemFailure(amountToSend);
    }

    function enterTheCode() external {
        countdown = block.timestamp + 18 hours;
        emit CodeEntered();
    }
}