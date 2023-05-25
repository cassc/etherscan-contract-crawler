// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMonaco.sol";
import "./interfaces/IMonacoMetadata.sol";

contract Monaco is ERC721Enumerable, Ownable, IMonaco, IMonacoMetadata, ReentrancyGuard {

  using Strings for uint256;
  
  uint256 public constant TOTAL_LIMIT = 10000;

  uint256 public constant WHITELIST_LIMIT = 1450;

  uint256 public constant RESERVE_MONACO = 150;
  
  uint256 public constant MAX_MINT = 5;  

  uint256 public constant MINT_PRICE = 0.03 ether;

  bool public isWhiteListMintActive;

  bool public isMintActive;

  uint256 public mintIndex;

  mapping(address => bool) private _whiteList;

  string private _contractURI;
  
  string private _tokenBaseURI;

  constructor(
    string memory name,
    string memory symbol
  ) ERC721(name, symbol) {}

  function isOnWhiteList(address addr)
    external
    view
    override
    returns (bool)
  {
    return _whiteList[addr];
  }  

  function addToWhiteList(address[] calldata addresses)
    external
    override
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can not add the null address");
      _whiteList[addresses[i]] = true;
    }
  }

  function removeFromWhiteList(address[] calldata addresses)
    external
    override
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can not add the null address");
      _whiteList[addresses[i]] = false;
    }
  }

  function whiteListMint()
    external
    override
    payable
    nonReentrant
  {
    require(isWhiteListMintActive,
            "whiteList mint not active");
    require(mintIndex + 1 < WHITELIST_LIMIT, "out of limit");        
    require(MINT_PRICE <= msg.value, "Ether value sent is not correct");
    require(_whiteList[msg.sender], "Address not in the white list");    

    uint256 tokenId = mintIndex;
    mintIndex++;
    _whiteList[msg.sender] = false;
    _safeMint(msg.sender, tokenId);
  }

  function mint(uint256 numberOfMonaco)
    external
    override
    payable
    nonReentrant
  {
    require(isMintActive,
            "mint not active");
    require(numberOfMonaco <= MAX_MINT, "out of max mint");        	    
    require(mintIndex + numberOfMonaco < TOTAL_LIMIT, "out of limit");        

    uint256 costToMint = MINT_PRICE * numberOfMonaco;
    require(costToMint <= msg.value, "Ether value sent is not correct");

    for (uint256 i = 0; i < numberOfMonaco; i++) {
      uint256 tokenId = mintIndex;    
      if (tokenId < TOTAL_LIMIT) {
        mintIndex++;
        _safeMint(msg.sender, tokenId);
      }
    }

    if (msg.value > costToMint) {
      payable(msg.sender).transfer(msg.value - costToMint);   
    }
  }  

  function withdraw() external override onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setWhiteListMintActive(bool active) external override onlyOwner {
    isWhiteListMintActive = active;
  }

  function setMintActive(bool active) external override onlyOwner {
    isMintActive = active;
  }

  function setContractURI(string calldata URI) external override onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external override onlyOwner {
    _tokenBaseURI = URI;
  }

  function contractURI() public view override returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "Token does not exist");
    return bytes(_tokenBaseURI).length > 0 ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString())) : "";
  }

  function reserveMonaco() public onlyOwner {        
    uint supply = totalSupply();
    uint i;
    for (i = 0; i < RESERVE_MONACO; i++) {
      mintIndex++;
      _safeMint(msg.sender, supply + i);
    }
  }


}