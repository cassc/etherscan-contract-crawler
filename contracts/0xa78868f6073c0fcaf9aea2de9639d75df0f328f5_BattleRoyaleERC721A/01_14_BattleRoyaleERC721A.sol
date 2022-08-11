// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract BattleRoyaleERC721A is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  /// @notice Event emitted when user minted tokens.
  event Minted(address user, uint256 quantity, uint256 totalSupply);
  event IsPublicSaleActiveSet(bool state);
  event IsPresaleActiveSet(bool state);
  event PriceSet(uint256 price);

  uint256 public immutable maxSupply;
  uint256 public immutable maxPubTokensPerWallet;
  uint256 public immutable maxPreTokensPerWallet;
  uint256 public immutable maxPubTokensPerTx;
  uint256 public immutable maxPreTokensPerTx;
  uint256 public immutable maxSupplyForTeam;
  uint256 public price;
  uint256 public totalSupplyForTeam;

  string private _baseTokenURI;

  bool public isPublicSaleActive = false;
  bool public isPresaleActive = false;
  bool public isRevealActive = false;

  mapping(address => uint256) public presaleCounter;
  mapping(address => uint256) public publicSaleCounter;

  // declare bytes32 variables to store root (a hash)
  bytes32 public merkleRoot;

  constructor(
    string memory name,
    string memory symbol,
    uint256 _maxPubTokensPerTx,
    uint256 _maxPreTokensPerTx,
    uint256 _maxSupplyForTeam,
    uint256 _maxSupply,
    uint256 _price,
    uint256 _maxPubTokensPerWallet,
    uint256 _maxPreTokensPerWallet
  ) ERC721A(name, symbol) {
    maxPubTokensPerTx = _maxPubTokensPerTx;
    maxPreTokensPerTx = _maxPreTokensPerTx;
    maxSupplyForTeam = _maxSupplyForTeam;
    maxSupply = _maxSupply;
    price = _price;
    maxPubTokensPerWallet = _maxPubTokensPerWallet;
    maxPreTokensPerWallet = _maxPreTokensPerWallet;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  // function to set the root of Merkle Tree
  function setMerkleRoot(bytes32 _root) external onlyOwner {
    merkleRoot = _root;
  }

  /*
   * Pause sale if active, make active if paused
   */
  function flipIsPublicSaleState() external onlyOwner {
    isPublicSaleActive = !isPublicSaleActive;

    emit IsPublicSaleActiveSet(isPublicSaleActive);
  }

  function flipIsPresaleState() external onlyOwner {
    isPresaleActive = !isPresaleActive;

    emit IsPresaleActiveSet(isPresaleActive);
  }

  // Internal for marketing, devs, etc
  function internalMint(uint256 _quantity, address _to) external onlyOwner nonReentrant {
    require(totalSupplyForTeam + _quantity <= maxSupplyForTeam, "Exceeded max supply for team");
    require(totalSupply() + _quantity <= maxSupply, "Exceeded max supply");

    _safeMint(_to, _quantity);

    totalSupplyForTeam += _quantity;

    emit Minted(_to, _quantity, totalSupply());
  }

  function presaleMint(uint256 _quantity, bytes32[] calldata _merkleProof)
    external
    payable
    callerIsUser
    nonReentrant
  {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(isPresaleActive, "Presale is not active");
    require(
      presaleCounter[msg.sender] + _quantity <= maxPreTokensPerWallet,
      "Exceeded max value to purchase"
    );
    require(_quantity <= maxPreTokensPerTx, "Exceeds max per transaction");
    require(totalSupply() + _quantity <= maxSupply, "Purchase would exceed max supply");
    require(price * _quantity <= msg.value, "Incorrect funds");
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid merkle proof");

    _safeMint(msg.sender, _quantity);

    presaleCounter[msg.sender] += _quantity;

    emit Minted(msg.sender, _quantity, totalSupply());
  }

  function publicSaleMint(uint256 _quantity) external payable callerIsUser nonReentrant {
    require(isPublicSaleActive, "Public sale is not active");
    require(
      publicSaleCounter[msg.sender] + _quantity <= maxPubTokensPerWallet,
      "Exceeded max value to purchase"
    );
    require(_quantity <= maxPubTokensPerTx, "Exceeds max per transaction");
    require(totalSupply() + _quantity <= maxSupply, "Purchase would exceed max supply");
    require(price * _quantity <= msg.value, "Incorrect funds");

    _safeMint(msg.sender, _quantity);

    publicSaleCounter[msg.sender] += _quantity;

    emit Minted(msg.sender, _quantity, totalSupply());
  }

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  // metadata URI

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI, bool reveal) external onlyOwner {
    _baseTokenURI = baseURI;
    if (reveal) {
      isRevealActive = reveal;
    }
  }

  function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
    require(_exists(tokenId), "Token does not exist");
    if (!isRevealActive) return _baseTokenURI;

    return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;

    emit PriceSet(price);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No ether left to withdraw");
    payable(msg.sender).transfer(balance);
  }
}