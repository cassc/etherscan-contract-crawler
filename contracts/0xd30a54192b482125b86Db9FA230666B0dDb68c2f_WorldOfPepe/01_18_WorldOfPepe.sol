// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "erc721a/contracts/ERC721A.sol";

contract WorldOfPepe is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  uint16 public maxSupply = 999;

  string public baseURI = "";

  bool public publicMintIsActive = false;
  uint256 public publicMintPrice = 0.039 ether;
  uint16 public publicMintTxLimit = 1;

  uint256 public whitelistMintPrice = 0.035 ether;
  uint16 public whitelistMintWalletLimit = 1;
  bool public whitelistMintIsActive = false;
  mapping(address => uint16) public whitelistTokensMinted;
  bytes32 public whitelistMerkleRoot = 0x0;

  address[] payees = [
    0xA2720113d1912b0b8Dfae2f0c0C8BD458Ca3Fe50,
    0x8aDe5Cf843f727B9c57a8E825026724848b340ff
  ];

  uint256[] payeeShares = [
    50,
    50
  ];

  constructor()
    ERC721A("World of Pepe", "WORLDOFPEPE")
    PaymentSplitter(payees, payeeShares)
  {
  }

  function tokensRemaining() public view returns (uint256) {
    return uint256(maxSupply).sub(totalSupply());
  }

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenIdsIdx;
    address currOwnershipAddr;
    uint256 tokenIdsLength = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenIdsLength);
    TokenOwnership memory ownership;

    for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; i++) {
      ownership = _ownerships[i];
      if (ownership.burned) {
        continue;
      }
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == _owner) {
        tokenIds[tokenIdsIdx++] = i;
      }
    }
    return tokenIds;
  }

  function publicMint(uint16 _quantity) external payable nonReentrant {
    require(publicMintIsActive, "mint is disabled");
    require(_quantity <= publicMintTxLimit && _quantity <= tokensRemaining(), "invalid mint quantity");
    require(msg.value >= publicMintPrice.mul(_quantity), "invalid mint value");

    _safeMint(msg.sender, _quantity);
  }

  function whitelistMint(bytes32[] calldata _merkleProof, uint16 _quantity) external payable nonReentrant {
    require(whitelistMintIsActive, "inactive");
    require(_quantity <= tokensRemaining(), "insufficient supply");
    require(msg.value >= whitelistMintPrice.mul(_quantity), "insufficient funds");
    
    uint16 alreadyMinted = whitelistTokensMinted[_msgSender()];
    require(_quantity + alreadyMinted <= whitelistMintWalletLimit, "exceeds wallet limit");

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "not on whitelist");

    _safeMint(_msgSender(), _quantity);

    whitelistTokensMinted[_msgSender()] = alreadyMinted + _quantity;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "invalid token");
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : '';
  }

  function setBaseURI(string memory _baseUri) external onlyOwner {
    baseURI = _baseUri;
  }

  function reduceMaxSupply(uint16 _maxSupply) external onlyOwner {
    require(_maxSupply < maxSupply, "must be less than curernt max supply");
    require(_maxSupply >= totalSupply(), "must be gte the total supply");
    maxSupply = _maxSupply;
  }

  function airDrop(address _to, uint16 _quantity) external onlyOwner {
    require(_to != address(0), "invalid address");
    require(_quantity > 0 && _quantity <= tokensRemaining(), "invalid quantity");
    _safeMint(_to, _quantity);
  }

  // Public

  function setPublicMintIsActive(bool _publicMintIsActive) external onlyOwner {
    publicMintIsActive = _publicMintIsActive;
  }

  function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
    publicMintPrice = _publicMintPrice;
  }

  function setPublicMintTxLimit(uint16 _publicMintTxLimit) external onlyOwner {
    publicMintTxLimit = _publicMintTxLimit;
  }

  // Whitelist

  function setWhitelistMintIsActive(bool _whitelistMintIsActive) external onlyOwner {
    whitelistMintIsActive = _whitelistMintIsActive;
  }

  function setWhitelistMintPrice(uint256 _whitelistMintPrice) external onlyOwner {
    whitelistMintPrice = _whitelistMintPrice;
  }

  function setWhitelistMintWalletLimit(uint16 _whitelistMintWalletLimit) external onlyOwner {
    whitelistMintWalletLimit = _whitelistMintWalletLimit;
  }

  function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
    whitelistMerkleRoot = _whitelistMerkleRoot;
  }
}