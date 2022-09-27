// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LoversTillDeath is ERC721A, Ownable, ReentrancyGuard {

 
  using Strings for uint;
 string public hiddenMetadataUri;


  string  public  baseTokenURI = "ipfs://QmUSwSEzTiysbrkgcpCVCUHdSPDcNR7eTC2f8iT5Kacnvs/";
  uint256  public  maxSupply = 1201;
  uint256 public  MAX_MINTS_PER_TX = 5;
  uint256 public  PUBLIC_SALE_PRICE = 0.015 ether;
  uint256 public  NUM_FREE_MINTS = 601;
  uint256 public  MAX_FREE_PER_WALLET = 1;
  uint256 public freeNFTAlreadyMinted = 0;
  bool public isPublicSaleActive = false;

   constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setHiddenMetadataUri(_hiddenMetadataUri);
  }


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

function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);

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
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
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

  function collectReserves() external onlyOwner {
    require(totalSupply() == 0, "Reserves already taken");

    _mint(msg.sender, 50);
  }

}