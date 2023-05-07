// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepechainAidropLock is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public releaseTime;

    // 2 months duration in seconds (60 days * 24 hours * 60 minutes * 60 seconds)
    uint256 private constant LOCK_DURATION = 60 * 24 * 60 * 60;

    constructor(IERC20 _token) {
        token = _token;
        releaseTime = block.timestamp.add(LOCK_DURATION);
    }

    function release() public onlyOwner {
        require(block.timestamp >= releaseTime, "AidropLock: current time is before release time");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "AidropLock: no tokens to release");

        token.transfer(owner(), amount);
    }
}