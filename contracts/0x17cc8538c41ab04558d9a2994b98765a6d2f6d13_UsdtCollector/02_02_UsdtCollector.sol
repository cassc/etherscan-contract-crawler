// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.17;

import "./TetherToken.sol";

contract UsdtCollector  {
    TetherToken token;
    
    function UsdtCollector() public {
        token = TetherToken(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }
  
    function withdraw() public {
        uint256 erc20balance = token.balanceOf(address(this));
        token.transfer(0x0f0012038Fb358D175Bc7F61fDf42807a70dac31, erc20balance);
    }    
}