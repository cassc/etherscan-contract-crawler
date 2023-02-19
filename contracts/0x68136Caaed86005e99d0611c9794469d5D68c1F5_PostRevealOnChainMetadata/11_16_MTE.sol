// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IOnChainMetadata.sol";
import "../tokens/erc721/custom-erc721/ERC721AEnumerable.sol";
import "../libraries/SymmetricEncryptionUtils.sol";

// import "@forge-std/src/console.sol";

error NotUnlockedYet();
error AlreadyUnlocked();
error MaxSupplyReached();
error AlreadyClaimed();
error InvalidSecret();
error InsufficientFunds();
error InvalidAmount();

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract MTE is ERC721AEnumerable, Ownable {
  IOnChainMetadata public metadata;
  bytes32 internal immutable secretHash;
  bytes internal hiddenLore;

  uint256 public immutable price;
  uint256 public immutable maxSupply;
  mapping(address => bool) public hasClaimed;
  string public externalUrl;

  mapping(uint256 => uint256) public tokenTypes;
  uint256 public constant CHOSEN_ONE = 1;
  uint256 public constant FREE_MINT = 2;
  uint256 public constant PREMIUM_MINT = 3;

  event Unlocked(address user);

  constructor(
    string memory name_,
    string memory symbol_,
    IOnChainMetadata metadataAddr_,
    bytes32 secretHash_,
    bytes memory hiddenLore_,
    uint256 maxSupply_,
    uint256 price_,
    string memory externalUrl_
  ) ERC721AEnumerable(name_, symbol_) {
    metadata = metadataAddr_;
    secretHash = secretHash_;
    hiddenLore = hiddenLore_;
    maxSupply = maxSupply_;
    price = price_;
    externalUrl = externalUrl_;
  }

  function setName(string memory name_) external onlyOwner {
    _name = name_;
  }

  function setSymbol(string memory symbol_) external onlyOwner {
    _symbol = symbol_;
  }

  function unlock(string memory secret) external {
    if (totalSupply() > 0) revert AlreadyUnlocked();
    if (totalSupply() >= maxSupply) revert MaxSupplyReached();
    if (keccak256(abi.encodePacked(secret)) != secretHash) revert InvalidSecret();
    emit Unlocked(msg.sender);
    tokenTypes[_nextTokenId()] = CHOSEN_ONE;
    _safeMint(msg.sender, 1);
  }

  function isUnlocked() external view returns (bool) {
    return totalSupply() > 0;
  }

  function mint(uint8 amount_) external payable {
    if (totalSupply() == 0) revert NotUnlockedYet();
    if (totalSupply() + amount_ > maxSupply) revert MaxSupplyReached();
    if (amount_ == 0) revert InvalidAmount();
    if (hasClaimed[msg.sender]) revert AlreadyClaimed();
    hasClaimed[msg.sender] = true;

    if (amount_ == 1) {
      tokenTypes[_nextTokenId()] = FREE_MINT;
      _safeMint(msg.sender, 1);
    } else if (amount_ == 2) {
      if (msg.value != price) revert InsufficientFunds();
      uint256 tokenId = _nextTokenId();
      tokenTypes[tokenId] = FREE_MINT;
      tokenTypes[tokenId + 1] = PREMIUM_MINT;
      _safeMint(msg.sender, 2);
    } else revert InvalidAmount();
  }

  function tokenURI(
    uint256 tokenId
  ) public view virtual override(IERC721A, ERC721A) returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    return metadata.tokenURI(tokenId);
  }

  function setExternalUrl(string memory externalUrl_) external onlyOwner {
    externalUrl = externalUrl_;
  }

  function h1dd3n(string memory secretKey) external view returns (string memory) {
    require(totalSupply() > 0, "Not unlocked yet");
    bytes32 decryptionKey = keccak256(abi.encodePacked(secretKey));

    return
      string(
        SymmetricEncryptionUtils.bytesTrimEnd(
          SymmetricEncryptionUtils.bytes32ArrToBytes(
            SymmetricEncryptionUtils.encrypt(
              decryptionKey,
              SymmetricEncryptionUtils.bytesToBytes32Arr(hiddenLore)
            )
          )
        )
      );
  }

  function reveal(IOnChainMetadata revealOnChainMetadataAddr_) external onlyOwner {
    metadata = revealOnChainMetadataAddr_;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}
// On Tupac's Soul