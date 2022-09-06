// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NSH is ERC20 {
    string public theIssuer;
    string public version;
    string public ensuringTheValueOfTokens;
    string public goalsOfImplementingOfTokens;

    uint8 public nominalPriceInUSD;
    uint256 public _totalSupply;

    constructor() ERC20("natural social human token","NSH") {
        _totalSupply=15000000000000000;
		
	
		version = "1.1";
		nominalPriceInUSD = 1;
		theIssuer = "CHARITY FUND ANTI-CRISIS ASSISTANCE";
		ensuringTheValueOfTokens = "human, social, natural capitals of Russia";
		goalsOfImplementingOfTokens = "investments in the growth of personal and total human, social, natural capitals";
		
		_mint(0x45afcE879244E4d6B6073D7005b57051Eca78a8C,_totalSupply*10**decimals());
    }
    function decimals() public view virtual override returns (uint8) {
        return 2;
    }
}