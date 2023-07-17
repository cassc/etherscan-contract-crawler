// SPDX-License-Identifier: MIT

/*
            Supply: 1500.
            Loopable: yes (on purpose, to save gas).
            Max per TX: 5.
            Mint Price: 0.007
            Mint Function: mint.
            Parameters: amount.
			Easy mint on: https://mint.neontools.me/
*/


pragma solidity ^ 0.8 .14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NeonTools is ERC721A, Ownable {

	// -------------------------------------//
	//              Configuration           //
	// -------------------------------------//
	uint256 public constant MAX_SUPPLY = 1500;

	string private BASE_URI; // Base URI for metadata
	uint256 IS_MAX_PER_TX;  // Max NFTs per transaction
	bool IS_PUBLIC_SALE_ACTIVE; // Public sale activation
	uint256 public MINT_PRICE;  // Mint price

	// -------------------------------------//
	//              Constructor             //
	// -------------------------------------//
	constructor() ERC721A("NeonTools", "NeonTools") {
		BASE_URI = "ipfs://QmTriVah7NxpPDLC97JoLjyY2joKUoPkjeL2PyuZjXQUM5";
		IS_MAX_PER_TX = 5;
		IS_PUBLIC_SALE_ACTIVE = false;
		MINT_PRICE = 0.007 ether;
		_safeMint(msg.sender, 1);
	}

	// -------------------------------------//
	//          Mint for public             //
	// -------------------------------------//
	function mint(uint256 amount) payable external {
		require(IS_PUBLIC_SALE_ACTIVE, "NeonTools :: Sale is inactive.");
		require(msg.value == amount * MINT_PRICE, "NeonTools :: Please send the correct value.");
		require(tx.origin == msg.sender, "NeonTools :: Please be yourself, not a contract.");
		require(amount <= IS_MAX_PER_TX, "NeonTools :: Max mints per TX");
		require(totalSupply() + amount <= MAX_SUPPLY, "NeonTools :: The supply cap is reached.");
		_safeMint(msg.sender, amount);
	}

	// -------------------------------------//
	//          Metadata Retriever          //
	// -------------------------------------//
	function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
		require(_exists(_tokenId), "URI query for non-existent token");
		return string(abi.encodePacked(BASE_URI));
	}

	// -------------------------------------//
	//          Makes token id 0 -> 1       //
	// -------------------------------------//
	function _startTokenId() internal view virtual override(ERC721A) returns(uint256) {
		return 1;
	}

	// -------------------------------------//
	//              Setters                 //
	// -------------------------------------//
	function setPublicSale(bool setActive, string memory _baseURI, uint256 maxPerTx, uint256 price) external onlyOwner {
		IS_PUBLIC_SALE_ACTIVE = setActive;
		BASE_URI = _baseURI;
		IS_MAX_PER_TX = maxPerTx;
		MINT_PRICE = price;
	}

	function activatePublicSale() external onlyOwner {
		IS_PUBLIC_SALE_ACTIVE = !IS_PUBLIC_SALE_ACTIVE;
	}

	// -------------------------------------//
	//          Withdraw Funds              //
	// -------------------------------------//
	function withdraw() external onlyOwner {
		require(address(this).balance != 0, "NeonTools :: No funds to withdraw.");
		(bool success, ) = owner().call {
			value: address(this).balance
		}("");
		require(success, "NeonTools :: ETH transfer failed");
	}
}