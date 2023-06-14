// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./RaffleAccessControl.sol";


/// @title A mintable NFT ticket for Coinburp Raffle
/// @author Valerio Leo @valerioHQ
contract RaffleTicket is ERC1155, RaffleAccessControl {
	constructor (string memory uri_) ERC1155(uri_) RaffleAccessControl(msg.sender, "BURP_RAFFLE_TICKET") {

	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	function mint(address to, uint256 tokenId, uint256 amount) external onlyMinter {
		super._mint(to, tokenId, amount, '');
	}
}