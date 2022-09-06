// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Mintable.sol";

/*
*  ______      __  __        __   __        __  __        __  __
* /\  ___\    /\ \/\ \      /\ "-.\ \      /\ \/ /       /\ \_\ \
* \ \  __\    \ \ \_\ \     \ \ \-.  \     \ \  _"-.     \ \____ \
*  \ \_\       \ \_____\     \ \_\\"\_\     \ \_\ \_\     \/\_____\
*   \/_/        \/_____/      \/_/ \/_/      \/_/\/_/      \/_____/
*
*  Web3 Has Lost It's Mojo
*  Funky Is Here To Restore It Back
*  Time To Enter The Funk
*/
contract Mojo is ERC721, Mintable {
	
	string public baseURI;
	
	constructor(
		address _owner,
		string memory _name,
		string memory _symbol,
		string memory _uri,
		address _imx
	) ERC721(_name, _symbol) Mintable(_owner, _imx) {
		setTokenUri(_uri);
	}
	
	function _mintFor(
		address user,
		uint256 id,
		bytes memory
	) internal override {
		_safeMint(user, id);
	}
	
	function setTokenUri(string memory _uri) public onlyOwner {
		baseURI = _uri;
	}
	
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);
		if (from != address(0)) {
			address owner = ownerOf(tokenId);
			require(owner == msg.sender, "Only the owner of NFT can transfer or burn it");
		}
	}
	
	function burn(uint256 tokenId) public {
		super._burn(tokenId);
	}
	
	function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}