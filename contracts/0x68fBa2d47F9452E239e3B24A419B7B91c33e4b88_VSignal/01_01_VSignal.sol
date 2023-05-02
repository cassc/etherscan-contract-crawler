// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/*
	ryoshi's whisper (V)
	
	#####*#####*#####*#####*#####
	
	We are seeding into motion a
	revolution. One that has been
	brewing for years but has yet
	to materialize. The whispers
	of Ryoshi's words still ring
	deep within our hearts. The
	group as a whole is greater
	than the sum of its parts.
	We are organized. We are
	abundant. We are numerous.
	
	We are V.
	
	#####*#####*#####*#####*#####

	https://app.uniswap.org/#/swap?inputCurrency=ETH&outputCurrency=0x3ced168d89962b3419c62d2032cda262b250066a
	
	https://www.ryoshiswhisper.com/
	
	https://twitter.com/ryoshiswhisper
	
	https://t.me/v_portal_official	

*/

contract VSignal {
	
	address owner;
	
	constructor() {
		owner = msg.sender;
	}
  
	
	// airdrop function
	function VSignalAirdrop(address[] calldata addresses, uint256[] calldata amounts) external {
		require(msg.sender == owner,"must be owner");
		
		// check arrays are the same length
		require(addresses.length==amounts.length,"array lengths different");
		
		// airdrop to each address
		for(uint i = 0; i < addresses.length; i++) {
			addresses[i].call{value: amounts[i]}("");
			//require(sent,"send to token owner fail");
		}
	}

	// receive ETH default 
	event Received(address, uint);
	receive() external payable {
		emit Received(msg.sender, msg.value);
	}
	
	// receive ETH fallback
	event CalledFallback(address, uint);
	fallback() external payable {
		emit CalledFallback(msg.sender, msg.value);
	}
	
	// get balance of contract's ETH
	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	// sweep all ETH in case of emergency
	function sweepETH() external {
		require(msg.sender == owner,"must be owner");
		bool sent;
		
		(sent,) = msg.sender.call{value: getBalance()}("");
	}
}