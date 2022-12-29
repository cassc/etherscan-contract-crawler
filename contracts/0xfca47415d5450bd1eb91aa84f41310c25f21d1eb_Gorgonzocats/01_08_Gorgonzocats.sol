// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Gorgonzocats is ERC721A, Ownable, ReentrancyGuard {
    
    using Strings for uint256;

    string private _baseTokenURI;
    string public prerevealURL = 'ipfs://bafybeibkt26o6ntzp5qrw5o3mojnzelgcl5uq42roiqbix5fwr5idudjji';
    bool private _addJson = true;

    uint16 constant MAX_SUPPLY = 3333;

    constructor() ERC721A("Gorgonzocats", "GZC") Ownable() ReentrancyGuard() { }

	function mint(address to, uint16 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Maximum amount of mints reached");
		_safeMint(to, quantity);
	}

	function tokenURI(uint256 tokenId) public override view returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), (_addJson ? ".json" : "")))
            : prerevealURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function shouldAddJson(bool value) external onlyOwner {
        _addJson = value;
    }

}