// SPDX-License-Identifier: CC0
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Turbulence is ERC721A, Ownable {
	uint16 public maxSupply = 1000;
	uint8 public maxPerWallet = 50;
	uint64 public price = 0.001 ether;
	string private baseURI = "ipfs://bafybeifywaxjnjlzpit257nb2n6i2gtfizdnjvhece6h3i76y5v7lqr5ti/";

	constructor() ERC721A("Turbulence", "TRB") {}

	function mint(uint256 quantity) external payable {
		require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
		require(balanceOf(msg.sender) + quantity <= maxPerWallet, "Exceeded per wallet limit");
		require(msg.value >= quantity * price, "Incorrect ETH amount");
		// require(tx.origin == _msgSender(), "No contracts");
		_safeMint(msg.sender, quantity);
	}

	function _startTokenId() internal pure override returns (uint256) {
		return 1;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
	}

	function withdraw() external payable onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}
}