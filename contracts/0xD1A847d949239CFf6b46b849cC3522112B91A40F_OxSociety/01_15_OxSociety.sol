// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libraries/ERC2981/ERC2981Base.sol";

contract OxSociety is ERC1155, ERC2981Base, Ownable {
  using Strings for uint256;
  using SafeMath for uint256;

  string public constant CONTRACT_METADATA =
    "https://0x-society.s3.us-east-2.amazonaws.com/0xMetadata/contract-level-metadata.json";

  mapping(uint256 => uint256) public _tokenSupply;
  mapping(uint256 => address) public _artistsWallet;
  mapping(uint256 => uint256) public _tokenMaxSupply;

  uint256 public _artistPayoutBasisPoint;
  uint256 public _currentTokenTypeID = 0; // Used to keep track of the number of different NFTs
  uint256 public _notNftprice = 0.05 ether;
  uint256 public _nftPrice = 0.5 ether;
  bool public _paused = true;
  string public _baseURI =
    "https://0x-society.s3.us-east-2.amazonaws.com/0xMetadata/";
  uint256 public _artistPayoutPercentage = 85;

  RoyaltyInfo public _royalties;

  constructor()
    ERC1155(
      "https://0x-society.s3.us-east-2.amazonaws.com/0xMetadata/{id}.json"
    )
  {}

  // modifiers
  modifier noContractCaller() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier isNotPaused() {
    require(!_paused, "The contract is paused");
    _;
  }

  // External functions

  function mint(
    address receiver,
    uint256 typeId,
    uint256 quantity
  ) public payable noContractCaller isNotPaused {
    uint256 tokenSupply = _tokenSupply[typeId];
    uint256 tokenMaxSupply = _tokenMaxSupply[typeId];
    uint256 mintPrice;

    if (tokenMaxSupply == 1) {
      mintPrice = _nftPrice;
    } else {
      mintPrice = _notNftprice;
    }

    require(msg.value >= mintPrice * quantity, "Insufficient funds");

    require(tokenMaxSupply > 0, "Token does not exist");

    require(
      tokenSupply + quantity <= tokenMaxSupply,
      "Token supply is greater than max supply"
    );

    _mint(receiver, typeId, quantity, "");

    _tokenSupply[typeId] = _tokenSupply[typeId].add(quantity);

    payable(_artistsWallet[typeId]).transfer(
      (quantity * mintPrice * _artistPayoutPercentage) / 100
    );
  }

  /**
   * @dev Creates a new token type and assigns _initialSupply to an address
   * @return The newly created token ID
   */
  function create(uint256 maxSupply, address artistWallet)
    external
    onlyOwner
    returns (uint256)
  {
    uint256 _id = _getNextTokenTypeID();
    _incrementTokenTypeId();
    _tokenMaxSupply[_id] = maxSupply;
    _artistsWallet[_id] = artistWallet;
    return _id;
  }

  function royaltyInfo(uint256, uint256 value)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  //  Setters

  /**
   * @dev Sets token royalties
   * @param recipient recipient of the royalties
   * @param value percentage (using 2 decimals : 10000 = 100%, 0 = 0%)
   */

  function setRoyalties(address recipient, uint256 value) external onlyOwner {
    require(value <= 10000, "ERC2981Royalties: Too high");
    _royalties = RoyaltyInfo(recipient, uint24(value));
  }

  function setNftPrice(uint256 value) external onlyOwner {
    _nftPrice = value;
  }

  function setNotNftPrice(uint256 value) external onlyOwner {
    _notNftprice = value;
  }

  function setPaused(bool paused) external onlyOwner {
    _paused = paused;
  }

  function setArtistPayoutPercentage(uint256 value) external onlyOwner {
    _artistPayoutPercentage = value;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseURI = baseURI;
  }

  // Public functions
  function uri(uint256 typeId) public view override returns (string memory) {
    require(_tokenMaxSupply[typeId] > 0, "Token does not exist");

    return string(abi.encodePacked(_baseURI, typeId.toString(), ".json"));
  }

  /**
   * @dev Returns the total quantity for a type of token
   * @param typeId uint256 ID of the token type to query
   * @return amount of token in existence
   */
  function totalSupply(uint256 typeId) public view returns (uint256) {
    return _tokenSupply[typeId];
  }

  function contractURI() public pure returns (string memory) {
    return CONTRACT_METADATA;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, ERC2981Base)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // Private functions

  /**
   * @dev calculates the next token ID based on value of _currentTokenID
   * @return uint256 for the next token ID
   */
  function _getNextTokenTypeID() private view returns (uint256) {
    return _currentTokenTypeID.add(1);
  }

  /**
   * @dev increments the value of _currentTokenID
   */
  function _incrementTokenTypeId() private {
    _currentTokenTypeID++;
  }
}