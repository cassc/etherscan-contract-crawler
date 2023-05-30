// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract STARFKRS is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter internal tokenIdCounter;

  string public provenance;

  bool public isRevealed;
  bool public isClaimActive;

  string public baseURI;
  string public preRevealURI;

  uint256 public maxSupply;

  mapping(address => bool) hasAddressMinted;

  function setProvenance(string memory _provenance) external onlyOwner {
    provenance = _provenance;
  }

  function setClaimActive() external onlyOwner {
    isClaimActive = !isClaimActive;
  }

  function setIsRevealed() external onlyOwner {
    isRevealed = !isRevealed;
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function setPreRevealURI(string memory _preRevealURI) external onlyOwner {
    preRevealURI = _preRevealURI;
  }

  function getBaseURI() public view virtual returns (string memory) {
    return baseURI;
  }

  function getSupply() external view returns (uint256) {
    return tokenIdCounter.current();
  }

  function claim() public nonReentrant {
    require(isClaimActive, "Claim is not active");
    require(!hasAddressMinted[_msgSender()], "Already claimed.");
    require(
			tokenIdCounter.current() + 1 <= maxSupply,
			"Exceeds max supply."
		);

    tokenIdCounter.increment();
    _safeMint(_msgSender(), tokenIdCounter.current());

    hasAddressMinted[_msgSender()] = true;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
   require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    if (!isRevealed) {
      return preRevealURI;
    }

    return string(abi.encodePacked(baseURI, abi.encodePacked(_toString(_tokenId)), ".json"));
  }

  function _toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT license
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}

  constructor() ERC721("Starfkrs", 'STARFKR') Ownable() {
    isClaimActive = false;
    isRevealed = false;
    maxSupply = 5000;
    provenance = "";
  }
}