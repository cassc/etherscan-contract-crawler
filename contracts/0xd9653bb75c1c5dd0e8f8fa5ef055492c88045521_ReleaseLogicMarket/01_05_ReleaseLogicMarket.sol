// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ReleaseLogicMarket {
    address public FMB = 0x52284158E02425290f6B627Aeb5FFF65eDf058Ad;
    uint256 public CLIFF = 0;
    uint256 public PERIOD = 0;
    uint256 public RELEASE = 97000000 * 10 ** 18;
    uint256 public tokenInitTS = 1683724175;
    uint256 public lastReleasedTS = 1683724175;
    address public beneficiary = 0xA22B49571Bf44aFc5c77563CbD3F5e77CFA1f9d5; 
        

    function initialize() public{
        FMB = 0x52284158E02425290f6B627Aeb5FFF65eDf058Ad;
        beneficiary = 0xA22B49571Bf44aFc5c77563CbD3F5e77CFA1f9d5;
        CLIFF = 0;
        PERIOD = 0;
        RELEASE = 97000000 * 10 ** 18;
        tokenInitTS = 1683724175;
        lastReleasedTS = 1683724175;
    }

    function _release(uint256 releasedAmount) internal {
        IERC20 token = IERC20(FMB);
        token.transfer( beneficiary, releasedAmount);
    }

    function claim(uint256 _amount) external {
        _release(_amount);        
    }

}