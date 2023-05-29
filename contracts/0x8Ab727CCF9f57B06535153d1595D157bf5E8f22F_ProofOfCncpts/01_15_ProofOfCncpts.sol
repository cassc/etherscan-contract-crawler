// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./external/ERC721AWithRoyalties.sol";

// @author rollauver.eth

contract ProofOfCncpts is Ownable, ERC721AWithRoyalties, Pausable {
  string public _baseTokenURI;

  uint256 public _price;
  uint256 public _maxSupply;
  uint256 public _maxPerAddress;
  uint256 public _publicSaleTime;
  uint256 public _maxTxPerAddress;
  mapping(address => uint256) private _purchases;

  event Purchase(address indexed addr, uint256 indexed atPrice, uint256 indexed count);

  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    uint256[] memory numericValues, // price - 0, maxSupply - 1, maxPerAddress - 2, publicSaleTime - 3, _maxTxPerAddress - 4
    address royaltyRecipient,
    uint256 royaltyAmount
  ) ERC721AWithRoyalties(name, symbol, numericValues[1], royaltyRecipient, royaltyAmount) {
    _baseTokenURI = baseTokenURI;

    _price = numericValues[0];
    _maxSupply = numericValues[1];
    _maxPerAddress = numericValues[2];
    _publicSaleTime = numericValues[3];
    _maxTxPerAddress = numericValues[4];
  }

  function setSaleInformation(
    uint256 publicSaleTime,
    uint256 maxPerAddress,
    uint256 price,
    uint256 maxTxPerAddress
  ) external onlyOwner {
    _publicSaleTime = publicSaleTime;
    _maxPerAddress = maxPerAddress;
    _price = price;
    _maxTxPerAddress = maxTxPerAddress;
  }

  function setBaseUri(
    string memory baseUri
  ) external onlyOwner {
    _baseTokenURI = baseUri;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return string(
      abi.encodePacked(
        _baseTokenURI,
        Strings.toHexString(uint256(uint160(address(this))), 20),
        '/'
      )
    );
  }

  function mint(address to, uint256 count) external payable onlyOwner {
    ensureMintConditions(count);

    _safeMint(to, count);
  }

  function purchase(uint256 count) external payable whenNotPaused {
    ensurePublicMintConditions(msg.sender, count, _maxPerAddress);
    require(isPublicSaleActive(), "BASE_COLLECTION/CANNOT_MINT");

    _purchases[msg.sender] += count;
    _safeMint(msg.sender, count);
    emit Purchase(msg.sender, _price, count);
  }

  function ensureMintConditions(uint256 count) internal view {
    require(totalSupply() + count <= _maxSupply, "BASE_COLLECTION/EXCEEDS_MAX_SUPPLY");
  }

  function ensurePublicMintConditions(address to, uint256 count, uint256 maxPerAddress) internal view {
    ensureMintConditions(count);

    require((_maxTxPerAddress == 0) || (count <= _maxTxPerAddress), "BASE_COLLECTION/EXCEEDS_MAX_PER_TRANSACTION");
    uint256 totalMintFromAddress = _purchases[to] + count;
    require ((maxPerAddress == 0) || (totalMintFromAddress <= maxPerAddress), "BASE_COLLECTION/EXCEEDS_INDIVIDUAL_SUPPLY");
  }

  function isPublicSaleActive() public view returns (bool) {
    return (_publicSaleTime == 0 || _publicSaleTime < block.timestamp);
  }

  function isPreSaleActive() public pure returns (bool) {
    return false;
  }

  function MAX_TOTAL_MINT() public view returns (uint256) {
    return _maxSupply;
  }

  function PRICE() public view returns (uint256) {
    return _price;
  }

  function MAX_TOTAL_MINT_PER_ADDRESS() public view returns (uint256) {
    return _maxPerAddress;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}