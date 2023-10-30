// https://www.gmcafe.io/migrate
/// @author raffy.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/[email protected]/access/Ownable.sol";

interface GMOOStub {
	function ownerOf(uint256 moo) external view returns (address);
	function mooFromToken(uint256 token) external view returns (uint256); 
	function safeTransferFrom(address from, address to, uint256 moo) external;
}

interface OpenSeaStub {
	function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, 
		uint256[] calldata amounts, bytes calldata data) external;
}

contract GMOORedeem is Ownable {

	address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

	GMOOStub constant GMOO_NFT = GMOOStub(0xE43D741e21d8Bf30545A88c46e4FF5681518eBad);
	OpenSeaStub constant OPENSEA_NFT = OpenSeaStub(0x495f947276749Ce646f68AC8c248420045cb7b5e); 
	address public _wallet = 0x00007C6cf9bF9B62B663f35542F486747a86D9D1;

	function setWallet(address a) onlyOwner public {
		_wallet = a;
	}

	function redeemMoos(uint256[] calldata tokens) public {
		uint256 n = tokens.length;
		require(n > 0, "no moos");
		uint256[] memory balances = new uint256[](n);		
		for (uint256 i; i < n; ) {
			balances[i] = 1;
			unchecked { i++; }
		}
		OPENSEA_NFT.safeBatchTransferFrom(msg.sender, BURN_ADDRESS, tokens, balances, ''); 
		for (uint256 i; i < n; ) {
			uint256 moo = GMOO_NFT.mooFromToken(tokens[i]);
			GMOO_NFT.safeTransferFrom(_wallet, msg.sender, moo);
			unchecked { i++; }
		}
	}

}