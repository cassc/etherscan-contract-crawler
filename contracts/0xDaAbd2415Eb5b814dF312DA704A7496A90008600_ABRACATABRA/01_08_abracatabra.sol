// SPDX-License-Identifier: MIT
//
// _ __    __| | __ _  _ __  |___ \    / \   |_   _| _ __    __| | __ _  _ __  
//| '_ \  / _` ||__` || '_ \     | |  / _ \    | |  | '_ \  / _` ||__` || '_ \ 
//| |_) || (_| |   | || |_) | ___| | / ___ \   | |  | |_) || (_| |   | || |_) |
//|_.__/  \__,_|   |_||_.__/ |____/ /_/   \_\  |_|  |_.__/  \__,_|   |_||_.__/ 
//
//

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ABRACATABRA is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.0125 ether;
  uint256 public maxSupply = 3500;
  uint256 public MaxperWallet = 33;
  bool public paused = true;
  bool public revealed = false;

  constructor(
    string memory _initBaseURI,
    string memory _notRevealedUri
  ) ERC721A("ABRACATABRA", "ABRCT") { 
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_notRevealedUri);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  function mint(uint256 tokens) public payable nonReentrant {
    require(!paused, "abraCATabra: The contract is paused!");
    require(tokens <= MaxperWallet, "abraCATabra: max mint amount per tx exceeded!");
    require(totalSupply() + tokens <= maxSupply, "abraCATabra: We Soldout!");
    require(_numberMinted(_msgSenderERC721A()) + tokens <= MaxperWallet, "abraCATabra: max NFT per wallet exceeded!");
    require(msg.value >= cost * tokens, "abraCATabra: insufficient funds");

      _safeMint(_msgSenderERC721A(), tokens);
  }
  

     function airdrop(uint256 _mintAmount, address destination) public onlyOwner nonReentrant {
    require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");

      _safeMint(destination, _mintAmount);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721AMetadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

      function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }

  function setMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWallet = _limit;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
 function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}