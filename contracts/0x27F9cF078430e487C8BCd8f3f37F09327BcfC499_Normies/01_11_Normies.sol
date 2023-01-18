// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Normies is ERC721, Ownable {

	using Strings for uint;

	uint public constant maxSupply = 1000;

	uint public mintedSupply;

	mapping(address => uint8) private addressMintedAmount;
	string private baseURI;
	
	modifier overallSupplyCheck() {

		require(mintedSupply < maxSupply, "All Normies have been minted");
		_;

	}

	constructor() ERC721("Normies", "NRMS") {}
	
	function remainingNFTs() private view returns (string memory) {
		
        return string(abi.encodePacked("Only ", (maxSupply - mintedSupply).toString(), " Normies left in supply"));
    }
	
	function tokenURI(uint tokenId) public view virtual override returns (string memory) {
		
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

		return bytes(baseURI).length > 0
			? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
			: "";

	}

	function mint(uint mintAmount) external overallSupplyCheck {
		
		require(mintAmount > 0 && mintAmount < 3, "Must mint 1 or 2 Normies at a time");
		require(addressMintedAmount[msg.sender] + mintAmount < 3, "Maximum 2 Normies minted per wallet");
		require(mintedSupply + mintAmount <= maxSupply, remainingNFTs());
				
		uint currSupply = mintedSupply;
		
		mintedSupply += mintAmount;
		
        for (uint i = 1; i <= mintAmount; i++) {
            addressMintedAmount[msg.sender]++;
            _safeMint(msg.sender, currSupply + i);
        }
	}
	
	// onlyOwner
	function setBaseURI(string memory newBaseURI) public onlyOwner {

		baseURI = newBaseURI;

	}

}