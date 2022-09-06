// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BuyThisNFTorApellDoit is ERC721A, Ownable, ReentrancyGuard {
  using Address for address;
  using Strings for uint;

  string  public  baseTokenURI = "ipfs://QmSXQ7hMVRFHZ2QRFAzHAzXDkrNsPQcwWEoNbsGznY7XSh";

  uint256 public  maxSupply = 6969;
  uint256 public  MAX_MINTS_PER_TX = 20;
  uint256 public  FREE_MINTS_PER_TX = 10;
  uint256 public  PUBLIC_SALE_PRICE = 0.005 ether;
  uint256 public  TOTAL_FREE_MINTS = 1500;
  bool public isPublicSaleActive = true;

  constructor(

  ) ERC721A("BuyThisNFTorApellDoit", "BTNA") {

  }

  function mint(uint256 numberOfTokens)
      external
      payable
  {
    require(isPublicSaleActive, "Public sale is not open");
    require(
      totalSupply() + numberOfTokens <= maxSupply,
      "Maximum supply exceeded"
    );
    require(numberOfTokens <= MAX_MINTS_PER_TX, "Maximum per tx exceeded");
    if((totalSupply() + numberOfTokens) > TOTAL_FREE_MINTS || numberOfTokens > FREE_MINTS_PER_TX){
        require(
            (PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value,
            "Incorrect ETH value sent"
        );
    }
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

  function setNumFreeMints(uint256 _numfreemints)
      external
      onlyOwner
  {
      TOTAL_FREE_MINTS = _numfreemints;
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