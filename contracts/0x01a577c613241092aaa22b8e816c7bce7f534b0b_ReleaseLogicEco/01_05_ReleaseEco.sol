// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ReleaseLogicEco {
    address public FMB = 0x52284158E02425290f6B627Aeb5FFF65eDf058Ad;
    uint256 public CLIFF = 6 * 30 days;
    uint256 public PERIOD = 30 days;
    uint256 public RELEASE = 4458333 * 10 ** 18;
    uint256 public FirstMonth_RELEASE = 50000000 * 10 ** 18;
    uint256 public tokenInitTS = 1683724175;
    uint256 public lastReleasedTS = 1683724175;
    address public beneficiary = 0x2CF47252C0ecD502d7A9012De50b0079B55a5b0e; 

    function _release(uint256 releasedAmount) internal {
        IERC20 token = IERC20(FMB);
        token.transfer( beneficiary, releasedAmount);
    }

    function claim() external {
        require(block.timestamp >= CLIFF + tokenInitTS && block.timestamp >= lastReleasedTS, "cliff now");
        lastReleasedTS = block.timestamp + PERIOD;
        _release(RELEASE);        
    }

    function claimFirstMonth() external {
        require(block.timestamp >= tokenInitTS + 30 days , "cliff now");
        _release(FirstMonth_RELEASE);        
    }

    function claimAll(uint256 _amount) external {
        require(block.timestamp >= 24 * PERIOD + CLIFF + tokenInitTS, "not end");
        _release(_amount);
    }

}