// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { WalletIndex } from './WalletIndex.sol';

contract dementorstownwtf is ERC721A, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  using WalletIndex for WalletIndex.Index;

  WalletIndex.Index private _claimedWalletIndexes;
  Counters.Counter private supply;

    string uriPrefix = "https://gateway.pinata.cloud/ipfs/QmYFidKdFXiSYaJUS187GUVqpkk2YrNmTsM9Bc7BPoyTrs/";
    uint256 public constant MAX_SUPPLY = 6666;
    uint256 public MINT_PRICE = 0.003 ether;
    uint256 public constant MAX_PER_TX = 3;
    uint256 public constant MAX_PER_TX_PUBLIC = 5; 
    uint256 public constant FREE_AMOUNT = 1666;
    uint256 public CLAIMED_SUPPLY;

    bool public IS_SALE_ACTIVE = false;

  constructor() ERC721A("dementorstownwtf", "DMTWTF") {} 

  function ownerMint(uint256 quantity) external payable {
      require(CLAIMED_SUPPLY + quantity <= MAX_SUPPLY, "Excedes max supply.");
      require(msg.sender == owner(), "You're not allowed for owner mint");
      require(quantity <= MAX_PER_TX_PUBLIC, "Exceeds max per transaction."); 
      _mint(msg.sender, quantity); 
      CLAIMED_SUPPLY += quantity;
  } 

   function publicMint(uint256 quantity) external payable {
        require(CLAIMED_SUPPLY + quantity <= MAX_SUPPLY, "Excedes max supply.");
        require(IS_SALE_ACTIVE,"Sale not active");
        require( _claimedWalletIndexes._getNextIndex(msg.sender) + quantity <= MAX_PER_TX_PUBLIC, "Requesting too many in claim");  
        if (CLAIMED_SUPPLY >= FREE_AMOUNT) {
          require( MINT_PRICE * quantity <= msg.value, "Ether value sent is not correct");
          require(quantity <= MAX_PER_TX_PUBLIC, "Exceeds max per transaction.");
         _mint(msg.sender, quantity);   
         CLAIMED_SUPPLY += quantity;
        }
        else{
        require(quantity <= MAX_PER_TX, "Exceeds max per transaction."); 
         _mint(msg.sender, quantity);   
         CLAIMED_SUPPLY += quantity;
        }
 
    }
 
     function totalMintedByWallet(address wallet) external view returns (uint256) {
        return _numberMinted(wallet);
    }

      function getNextClaimIndex(address wallet) external view returns (uint256) {
        return _claimedWalletIndexes._getNextIndex(wallet);
    }

  function toggleSale() public onlyOwner {
      IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }

  function _internalMintTokens(address minter, uint256 count) internal {
        require(totalSupply() + count <= MAX_SUPPLY, "Limit exceeded"); 
        _safeMint(minter, count);
    }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

 function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    ); 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
  }


  function setMINT_PRICE(uint256 _MINT_PRICE) public onlyOwner {
    MINT_PRICE = _MINT_PRICE;
  }

  
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
 

  function setURI(string memory URI) public onlyOwner {
      uriPrefix = URI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}