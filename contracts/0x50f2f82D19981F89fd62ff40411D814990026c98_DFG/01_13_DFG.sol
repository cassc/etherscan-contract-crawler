// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol"; 

contract DFG is ERC721A, Ownable, ReentrancyGuard {
  using Address for address;
  using Strings for uint;

  string  public  baseTokenURI = "https://ipfs.io/ipfs/bafybeiccikk7el3qqnywk22nhtifdktn7lqohi4k2g6lygmo3or5ua54nu";

  uint256 public maxSupply = 2000;
  uint256 public TOTAL_FREE_MINTS = 666;
  uint256 public MAX_MINTS_PER_TX = 10;
  uint256 public MAX_FREE_MINTS_PER_TX = 1;
  uint256 public PUBLIC_SALE_PRICE = 0.001 ether;

  bool public isPublicSaleActive = true;

  constructor(

  ) ERC721A("Doge Fireball Genesis", "DFG") {

  }

  function publicMint(uint256 numberOfTokens)
      external
      payable
  {
    require(numberOfTokens > 0, "Mint 1 at least");
    require(isPublicSaleActive, "Public sale is not open");
    require(
      totalSupply() + numberOfTokens <= maxSupply,
      "Maximum supply exceeded"
    );

    uint256 mintAmount = numberOfTokens;

    if (totalSupply() < TOTAL_FREE_MINTS) {
        mintAmount--;
    }
    
    require(msg.value >= PUBLIC_SALE_PRICE * mintAmount, "Insufficient ETH sent for mints");
    _safeMint(msg.sender, numberOfTokens);
  }

  function setBaseURI(string memory baseURI)
    public
    onlyOwner
  {
    baseTokenURI = baseURI;
  }

  function treasuryMint(uint quantity, address user)
    public
    onlyOwner
  {
    require(
      quantity > 0,
      "Invalid mint amount"
    );
    require(
      totalSupply() + quantity <= maxSupply,
      "Maximum supply exceeded"
    );
    _safeMint(user, quantity);
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
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
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

  function setIsPublicSaleActive(bool _isPublicSaleActive)
      external
      onlyOwner
  {
      isPublicSaleActive = _isPublicSaleActive;
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

}