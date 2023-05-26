/**
 * @title  Wasteland Smart Contract for Divine Anarchy
 * @author Diveristy - twitter.com/DiversityETH
 *
 * 8888b.  88 Yb    dP 88 88b 88 888888      db    88b 88    db    88""Yb  dP""b8 88  88 Yb  dP
 *  8I  Yb 88  Yb  dP  88 88Yb88 88__       dPYb   88Yb88   dPYb   88__dP dP   `" 88  88  YbdP
 *  8I  dY 88   YbdP   88 88 Y88 88""      dP__Yb  88 Y88  dP__Yb  88"Yb  Yb      888888   8P
 * 8888Y"  88    YP    88 88  Y8 888888   dP""""Yb 88  Y8 dP""""Yb 88  Yb  YboodP 88  88  dP
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A-Custom.sol";

contract Wasteland is Ownable, ERC721A {
	uint256 public constant MAX_SUPPLY = 5050;
	string public baseUri;
	bool public preReveal = true;

	constructor(string memory uri) ERC721A("Wasteland", "DAW") {
		baseUri = uri;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function airdrop(address[] memory wallets, uint256[] memory amount, uint256 total) external onlyOwner {
		require(totalSupply() + total <= MAX_SUPPLY, "Airdrop will surpass the max supply");
		uint256 walletCount = wallets.length;

		for(uint256 i; i < walletCount; i++) {
			// Shoutout to twitter.com/Mai_Jpegs for pushing me to simplify the mint function
			_customMint(wallets[i], amount[i]);
		}
	}

	function tokensOfOwner(address owner) public view returns (uint256[] memory) {
		uint256 holdingAmount = balanceOf(owner);
		uint256 currSupply = _currentIndex;
		uint256 tokenIdsIdx;
		address currOwnershipAddr;

		uint256[] memory list = new uint256[](holdingAmount);

		unchecked {
			for (uint256 i = _startTokenId(); i < currSupply; ++i) {
				TokenOwnership memory ownership = _ownerships[i];

				if (ownership.burned) {
					continue;
				}

				// Find out who owns this sequence
				if (ownership.addr != address(0)) {
					currOwnershipAddr = ownership.addr;
				}

				// Append tokens the last found owner owns in the sequence
				if (currOwnershipAddr == owner) {
					list[tokenIdsIdx++] = i;
				}

				// All tokens have been found, we don't need to keep searching
				if (tokenIdsIdx == holdingAmount) {
					break;
				}
			}
		}

		return list;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		return preReveal ? baseUri : super.tokenURI(tokenId);
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseUri;
	}

	function setPreReveal(bool isPreReveal) external onlyOwner {
		preReveal = isPreReveal;
	}

	function setBaseUri(string memory uri) external onlyOwner {
		baseUri = uri;
	}
}