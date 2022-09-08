// SPDX-License-Identifier: MIT

/* 

__________.__       .__         _____                  _____.___.       __         .__      _________ .__       ___.    
\______   \__| ____ |  |__     /  _  \ ______   ____   \__  |   |____ _/  |_  ____ |  |__   \_   ___ \|  |  __ _\_ |__  
 |       _/  |/ ___\|  |  \   /  /_\  \\____ \_/ __ \   /   |   \__  \\   __\/ ___\|  |  \  /    \  \/|  | |  |  \ __ \ 
 |    |   \  \  \___|   Y  \ /    |    \  |_> >  ___/   \____   |/ __ \|  | \  \___|   Y  \ \     \___|  |_|  |  / \_\ \
 |____|_  /__|\___  >___|  / \____|__  /   __/ \___  >  / ______(____  /__|  \___  >___|  /  \______  /____/____/|___  /
        \/        \/     \/          \/|__|        \/   \/           \/          \/     \/          \/               \/ 

*/


pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Richapeyatchclub is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.0009 ether;
  uint256 public maxSupply = 5000;
  uint256 public FreeSupply = 2500;
  uint256 public MaxperWallet = 1111;
  uint256 public MaxperWalletFree = 111;
  bool public paused = false;
  bool public revealed = true;

  constructor(
    string memory _initBaseURI,
    string memory _notRevealedUri
  ) ERC721A("Rich Ape Yatch Club", "RAYC") {  // change the name and symbol for your collection
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_notRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  // public
  /// @dev Public mint 
  function mint(uint256 tokens) public payable nonReentrant {
    require(!paused, "oops contract is paused");
    require(tokens <= MaxperWallet, "max mint amount per tx exceeded");
    require(totalSupply() + tokens <= maxSupply, "We Soldout");
    require(_numberMinted(_msgSenderERC721A()) + tokens <= MaxperWallet, "Max NFT Per Wallet exceeded");
    require(msg.value >= cost * tokens, "insufficient funds");

      _safeMint(_msgSenderERC721A(), tokens);
  }
  
/// @dev free mint
    function freemint(uint256 tokens) public nonReentrant {
    require(!paused, "oops contract is paused");
    require(_numberMinted(_msgSenderERC721A()) + tokens <= MaxperWalletFree, "Max NFT Per Wallet exceeded");
    require(tokens <= MaxperWalletFree, "max mint per Tx exceeded");
    require(totalSupply() + tokens <= FreeSupply, "Whitelist MaxSupply exceeded");

      _safeMint(_msgSenderERC721A(), tokens);
    
  }

  /// @dev use it for giveaway and team mint
     function airdrop(uint256 _mintAmount, address destination) public onlyOwner nonReentrant {
    require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");

      _safeMint(destination, _mintAmount);
  }

/// @notice returns metadata link of tokenid
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

     /// @notice return the number minted by an address
    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

    /// @notice return the tokens owned by an address
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

  //only owner
  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }

  /// @dev change the public max per wallet
  function setMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWallet = _limit;
  }

  /// @dev change the free max per wallet
    function setFreeMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWalletFree = _limit;
  }

   /// @dev change the public price(amount need to be in wei)
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  /// @dev cut the supply if we dont sold out
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

 /// @dev cut the free supply
    function setFreesupply(uint256 _newsupply) public onlyOwner {
    FreeSupply = _newsupply;
  }

 /// @dev set your baseuri
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  /// @dev set base extension(default is .json)
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

   /// @dev set hidden uri
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

 /// @dev to pause and unpause your contract(use booleans true or false)
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 
  function withdraw() public payable onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      payable(_msgSenderERC721A()).transfer(balance);
  }
}