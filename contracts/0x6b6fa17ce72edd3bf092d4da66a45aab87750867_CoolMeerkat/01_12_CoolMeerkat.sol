// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CoolMeerkat is ERC721A, Ownable, ReentrancyGuard {
  using Address for address;
  using Strings for uint;

  string  public  baseTokenURI = "ipfs://bafybeih4pmsiwscciu63lrxvafed2l4pkhnbcy2zu3wul4i3cqhhyu4gwm";
  bool public isPublicSaleActive = true;

  uint256 public  maxSupply = 2222;
  uint256 public  MAX_MINTS_PER_TX = 35;
  uint256 public  PUBLIC_SALE_PRICE = 0.009 ether;
  uint256 public  NUM_FREE_MINTS = 2222;
  uint256 public  MAX_FREE_PER_WALLET = 1;
  uint256 public  freeNFTAlreadyMinted = 0;

  constructor() ERC721A("Cool Meerkat", "CM") {}
  // @notice First 2 Free Mint Then 009 Ether
  function mint(uint256 numberOfTokens) external payable
  {
    require(isPublicSaleActive, "Public sale is paused.");
    require(totalSupply() + numberOfTokens < maxSupply + 1, "Maximum supply exceeded.");

    require(numberOfTokens <= MAX_MINTS_PER_TX, "Maximum mints per transaction exceeded.");

    if(freeNFTAlreadyMinted + numberOfTokens > NUM_FREE_MINTS)
    {
        require(PUBLIC_SALE_PRICE * numberOfTokens <= msg.value, "Invalid ETH value sent. Error Code: 1");
    } 
    else 
    {
        uint sender_balance = balanceOf(msg.sender);
        
        if (sender_balance + numberOfTokens > MAX_FREE_PER_WALLET) 
        { 
            if (sender_balance < MAX_FREE_PER_WALLET)
            {
                uint free_available = MAX_FREE_PER_WALLET - sender_balance;
                uint to_be_paid = numberOfTokens - free_available;
                require(PUBLIC_SALE_PRICE * to_be_paid <= msg.value, "Invalid ETH value sent. Error Code: 2");

                freeNFTAlreadyMinted += free_available;
            }
            else
            {
                require(PUBLIC_SALE_PRICE * numberOfTokens <= msg.value, "Invalid ETH value sent. Error Code: 3");
            }
        }  
        else 
        {
            require(numberOfTokens <= MAX_FREE_PER_WALLET, "Maximum mints per transaction exceeded");
            freeNFTAlreadyMinted += numberOfTokens;
        }
    }

    _safeMint(msg.sender, numberOfTokens);
  }

  function setBaseURI(string memory baseURI)
    public
    onlyOwner
  {
    baseTokenURI = baseURI;
  }

  function treasuryMint(uint quantity)
    public
    onlyOwner
  {
    require(quantity > 0, "Invalid mint amount");
    require(totalSupply() + quantity <= maxSupply, "Maximum supply exceeded");

    _safeMint(msg.sender, quantity);
  }

  function withdraw()
    public
    onlyOwner
    nonReentrant
  {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function tokenURI(uint _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString(), ".json"));
  }

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return baseTokenURI;
  }

  function getIsPublicSaleActive() 
    public
    view 
    returns (bool) {
      return isPublicSaleActive;
  }

  function getFreeNftAlreadyMinted() 
    public
    view 
    returns (uint256) {
      return freeNFTAlreadyMinted;
  }

  function setIsPublicSaleActive(bool _isPublicSaleActive)
      external
      onlyOwner
  {
      isPublicSaleActive = _isPublicSaleActive;
  }

  function setNumFreeMints(uint256 _numfreemints)
      external
      onlyOwner
  {
      NUM_FREE_MINTS = _numfreemints;
  }

  function getSalePrice()
  public
  view
  returns (uint256)
  {
    return PUBLIC_SALE_PRICE;
  }

  function setSalePrice(uint256 _price)
      external
      onlyOwner
  {
      PUBLIC_SALE_PRICE = _price;
  }

  function setMaxLimitPerTransaction(uint256 _limit)
      external
      onlyOwner
  {
      MAX_MINTS_PER_TX = _limit;
  }

  function setFreeLimitPerWallet(uint256 _limit)
      external
      onlyOwner
  {
      MAX_FREE_PER_WALLET = _limit;
  }
}