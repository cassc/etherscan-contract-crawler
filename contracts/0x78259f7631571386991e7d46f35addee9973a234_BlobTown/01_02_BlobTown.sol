pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT

import "./Base.sol";

contract BlobTown is ERC721A, Ownable, ReentrancyGuard {
  using Address for address;
  using Strings for uint;

  uint256 public  MAX_MINTS_PER_TX = 10;
  uint256 public  NUM_FREE_MINTS = 5000;
  uint256 public  PUBLIC_SALE_PRICE = 0.0069 ether;

  string  public  baseTokenURI = "ipfs://QmahcKG6B57Q1wNyqVS9X4R9hXF7mru9DJay4G88zkAnJz";
  uint256  public  maxSupply = 5000;
  bool public isPublicSaleActive = false;
  uint256 public freeNFTAlreadyMinted = 0;
  uint256 public  MAX_FREE_PER_WALLET = 1;

  constructor() ERC721A(
      "Blob Town",
      "BLOBTOWN"
    ) {}

  function mint(uint256 numberOfTokens)
      external
      payable
  {
    require(isPublicSaleActive, "Public sale is not open");
    require(totalSupply() + numberOfTokens < maxSupply + 1, "No more");

    if(freeNFTAlreadyMinted + numberOfTokens > NUM_FREE_MINTS){
        require(
            (PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value,
            "Incorrect ETH value sent"
        );
    } else {
        if (balanceOf(msg.sender) + numberOfTokens > MAX_FREE_PER_WALLET) {
        require(
            (PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value,
            "Incorrect ETH value sent"
        );
        require(
            numberOfTokens <= MAX_MINTS_PER_TX,
            "Max mints per transaction exceeded"
        );
        } else {
            require(
                numberOfTokens <= MAX_FREE_PER_WALLET,
                "Max mints per transaction exceeded"
            );
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
    require(
      quantity > 0,
      "Invalid mint amount"
    );
    require(
      totalSupply() + quantity <= maxSupply,
      "Maximum supply exceeded"
    );
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

  function setNumFreeMints(uint256 _numfreemints)
      external
      onlyOwner
  {
      NUM_FREE_MINTS = _numfreemints;
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