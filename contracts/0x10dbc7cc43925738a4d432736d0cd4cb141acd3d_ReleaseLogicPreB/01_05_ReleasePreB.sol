// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ReleaseLogicPreB {
    address public FMB = 0x52284158E02425290f6B627Aeb5FFF65eDf058Ad;
    uint256 public CLIFF = 6 * 30 days;
    uint256 public PERIOD = 30 days;
    uint256 public RELEASE = 6041666 * 10 ** 18;
    uint256 public tokenInitTS = 1683724175;
    uint256 public lastReleasedTS = 1683724175;
    address public beneficiary = 0x812Ad2110852689A8c3e97c15FA6D98a9383a0b9; 

    function _release(uint256 releasedAmount) internal {
        IERC20 token = IERC20(FMB);
        token.transfer( beneficiary, releasedAmount);
    }

    function claim() external {
        require(block.timestamp >= CLIFF + tokenInitTS && block.timestamp >= lastReleasedTS, "cliff now");
        lastReleasedTS = block.timestamp + PERIOD;
        _release(RELEASE);        
    }

    function claimAll(uint256 _amount) external {
        require(block.timestamp >= 12 * PERIOD + CLIFF + tokenInitTS, "not end");
        _release(_amount);
    }

}