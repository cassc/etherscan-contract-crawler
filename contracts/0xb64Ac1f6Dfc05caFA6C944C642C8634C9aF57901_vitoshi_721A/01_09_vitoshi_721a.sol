// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import './extensions/ERC721AQueryable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract vitoshi_721A is ERC721AQueryable,Ownable,ReentrancyGuard {  

  bytes32 public constant merkleRoot = 0xb10000bd15e0ec8e3457f2ada240653cd927c287b5ab2ed3c840ca3e3d74bd78;
  uint256 public constant TOTAL_SUPPLY_LIMIT = 6302;
  uint256 public constant MINT_PRICE = 0.008 ether;
  uint256 public constant WHITELIST_LIMIT_PER_WALLET = 8;
  string public baseTokenURI ="";
  bool public publicMintingOpen;
  bool public whitelistMintingOpen;
   
	constructor() ERC721A("Vitoshis Castle OutTakes", "VITOT") {}

     function airdrop(address[] memory airdrops, uint256 tokensForEach) external onlyOwner {
    require(tokensForEach + totalSupply() <= TOTAL_SUPPLY_LIMIT, "Exceeds Max Supply");
    require(tokensForEach <= 30,"<30/batch");
    for(uint i = 0; i < airdrops.length; i++) {
	    _mint(airdrops[i], tokensForEach);
    }
  }

    function mintFromWhitelist(bytes32[] calldata _merkleProof,uint64 contestantsToMint) public payable {
    require(whitelistMintingOpen == true, "Whitelist Sale Off");
    require(contestantsToMint + totalSupply() <= TOTAL_SUPPLY_LIMIT, "Exceeds Max Supply");
    require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not whitelisted");
 
    uint cost;    
    unchecked { cost = contestantsToMint * MINT_PRICE; }
    require(msg.value == cost, "Wrong payment");
    require( (_getAux(msg.sender) + contestantsToMint) <= WHITELIST_LIMIT_PER_WALLET , "Exceeds Whitelist Limit / Wallet");
    _setAux(msg.sender, _getAux(msg.sender) + contestantsToMint);

    _mint(msg.sender,contestantsToMint);

  }

  function mintFromSale(uint contestantsToMint) public payable {
      require(contestantsToMint + totalSupply() <= TOTAL_SUPPLY_LIMIT, "Exceeds Max Supply");
      require(publicMintingOpen == true, "Public Sale Off");
    uint cost;    
    unchecked { cost = contestantsToMint * MINT_PRICE; }
    require(msg.value == cost, "Wrong payment");
    require(contestantsToMint <= 30,"<30/batch");

    _mint(msg.sender,contestantsToMint);
  }

  function togglePublicSale() external onlyOwner {
	  publicMintingOpen = !publicMintingOpen;
  }

  function toggleWhitelistSale() external onlyOwner {
	  whitelistMintingOpen = !whitelistMintingOpen;
  }

  function retrieveFunds() external onlyOwner nonReentrant {
    payable(owner()).transfer(address(this).balance);
  }

  /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

}