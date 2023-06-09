// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ReleaseLogicDev {
    address public FMB = 0x52284158E02425290f6B627Aeb5FFF65eDf058Ad;
    uint256 public CLIFF = 6 * 30 days;
    uint256 public PERIOD = 30 days;
    uint256 public RELEASE = 125000000 * 10 ** 18;
    uint256 public tokenInitTS = 1683724175;
    uint256 public lastReleasedTS = 1683724175;
    address public beneficiary = 0x6286751fFc02363B06e211944343F75B0D6F0C67; 
        

    function initialize() public{
        FMB = 0x52284158E02425290f6B627Aeb5FFF65eDf058Ad;
        beneficiary = 0x6286751fFc02363B06e211944343F75B0D6F0C67;
        CLIFF = 6 * 30 days;
        PERIOD = 30 days;
        RELEASE = 125000000 * 10 ** 18;
        tokenInitTS = 1683724175;
        lastReleasedTS = 1683724175;
    }

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