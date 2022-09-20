/**
*/

// SPDX-License-Identifier: MIT
// https://twitter.com/virginsnft


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/ERC721A.sol";

pragma solidity >=0.8.7;

contract BoredVirginsYachtClub is ERC721A, Ownable {
  using Strings for uint256;

  string public baseuri;

  uint256 public cost = 0.003 ether;
  uint256 public maxSupply = 6969;
  uint256 public maxMintAmount = 20;

  bool public revealed = true;
  bool public paused = true;

  constructor()
    ERC721A("Bored Virgins Yacht Club", "BVYC")
{}

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "Virgins are not coming out to play today.");
    require(totalSupply() + _mintAmount <= maxSupply, "SOLD OUT.");
    require(_mintAmount <= 20, "Only 20  each time...");
    require(tx.origin == msg.sender, "No contract minting...");
    require( numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
       "You already have enough ..."
    );
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 costToSubtract = 0;
    
    if (numberMinted(msg.sender) < 1) {
      uint256 freeMintsLeft = 1 - numberMinted(msg.sender);
      costToSubtract = cost * freeMintsLeft;
    }
   
    require(msg.value >= cost * _mintAmount - costToSubtract, "Insufficient funds.");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }
  

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return '';
    }
else{
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
        }
  }


  function setPaused() public onlyOwner {
    paused = !paused;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseuri;
  }
  
	function setbaseUri( string memory newBaseURI ) external onlyOwner {
		baseuri = newBaseURI;
	}

  function withdraw() public onlyOwner {
		( bool os, ) = payable( owner() )
			.call {
				value: address( this )
					.balance
			}( "" );
		require( os );
	}
}