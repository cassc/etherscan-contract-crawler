// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Boki is ERC721A, Ownable, VRFConsumerBase {
  enum SaleStatus {
    PAUSED,
    DREAMERS,
    PUBLIC,
    ALLOWLIST,
    FINAL
  }

  using Strings for uint256;
  using ECDSA for bytes32;

  // ------ SET SALE AS PAUSED
  SaleStatus public saleStatus = SaleStatus.PAUSED;

  string private preRevealURI;
  string private postRevealBaseURI;

  // ------ Sale Settings
  uint256 private constant PRICE_BOKI = 0.066 ether;
  uint256 private constant MAX_BOKI = 7777;
  uint256 private constant DEPLOYER_RESERVED_BOKI = 150;
  uint256 private constant PUBLIC_BOKI_PER_TXN_LIMIT = 3;

  // Remaining public Bokis (7777-1263-3753-1263-150=1348)
  uint256 public publicBokiRemaining = 1348;
  bytes32 public dreamersMerkleRoot;
  bytes32 public allowlistMerkleRoot;
  address public publicMintSigner;

  mapping(address => bool) public dreamersPresalePurchased;
  mapping(address => bool) public allowlistSalePurchased;
  mapping(bytes => bool) public signaturesUsed;

  // ------ Reveal
  bool public revealed;
  uint256 public tokenOffset;

  // Chainlink VRF
  bytes32 public chainlinkKeyHash;
  uint256 public chainlinkFee;

  address private immutable withdrawalAddress;

  constructor(
    string memory _preRevealURI,
    address _withdrawalAddress,
    address _vrfCoordinator,
    address _linkAddress,
    bytes32 _chainlinkKeyHash,
    uint256 _chainlinkFee
  ) ERC721A("Boki", "BOKI") VRFConsumerBase(_vrfCoordinator, _linkAddress) {
    preRevealURI = _preRevealURI;
    withdrawalAddress = _withdrawalAddress;
    chainlinkKeyHash = _chainlinkKeyHash;
    chainlinkFee = _chainlinkFee;
    _mint(tx.origin, DEPLOYER_RESERVED_BOKI, "", false);
  }

  // ------ Prevention from minting off of Contract
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  // ------ METADATA
  function setPreRevealURI(string memory _URI) external onlyOwner {
    preRevealURI = _URI;
  }

  function setPostRevealBaseURI(string memory _URI) external onlyOwner {
    postRevealBaseURI = _URI;
  }

  // ------ TOKEN URI
  // Before reveal, return same pre-reveal URI
  // After reveal, return post-reveal URI with random token offset from Chainlink
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    if (!revealed) return preRevealURI;
    uint256 shiftedTokenId = (_tokenId + tokenOffset) % totalSupply();
    return string(abi.encodePacked(postRevealBaseURI, shiftedTokenId.toString()));
  }

  // ------ SALE FUNCTION

  function setSaleStatus(SaleStatus _status) external onlyOwner {
    saleStatus = _status;
  }

  // ------ MERKLE ROOTS
  function setMerkleRoots(bytes32 _dreamersMerkleRoot, bytes32 _allowlistMerkleRoot) external onlyOwner {
    dreamersMerkleRoot = _dreamersMerkleRoot;
    allowlistMerkleRoot = _allowlistMerkleRoot;
  }

  function processMint(uint256 _quantity) internal {
    require(!revealed, "NO MINTS POSTREVEAL");
    require(msg.value == PRICE_BOKI * _quantity, "INCORRECT ETH SENT");
    require(totalSupply() + _quantity <= MAX_BOKI, "MAX CAP OF BOKI EXCEEDED");
    _mint(msg.sender, _quantity, "", false);
  }

  //  ------ DREAMER PRESALE + DREAMER ALLOW LIST SALE
  function dreamersSale(bytes32[] memory _proof) external payable callerIsUser {
    require(saleStatus == SaleStatus.DREAMERS || saleStatus == SaleStatus.ALLOWLIST, "DREAMERS SALE NOT ACTIVE");
    require(
      MerkleProof.verify(_proof, dreamersMerkleRoot, keccak256(abi.encodePacked(msg.sender))),
      "MINTER IS NOT ON DREAMERS LIST"
    );
    if (saleStatus == SaleStatus.DREAMERS) {
      require(!dreamersPresalePurchased[msg.sender], "DREAMER PRESALE TICKET ALREADY USED");
      dreamersPresalePurchased[msg.sender] = true;
    } else {
      require(!allowlistSalePurchased[msg.sender], "DREAMER ALLOWLIST TICKET ALREADY USED");
      allowlistSalePurchased[msg.sender] = true;
    }

    processMint(1);
  }

  // ------ ALLOWLIST SALE
  function allowlistSale(bytes32[] memory _proof) external payable callerIsUser {
    require(saleStatus == SaleStatus.ALLOWLIST, "ALLOW LIST MINTING IS NOT ACTIVE");
    require(
      MerkleProof.verify(_proof, allowlistMerkleRoot, keccak256(abi.encodePacked(msg.sender))),
      "MINTER IS NOT ON ALLOW LIST"
    );
    require(!allowlistSalePurchased[msg.sender], "ALLOWLIST TICKET ALREADY USED");
    allowlistSalePurchased[msg.sender] = true;

    processMint(1);
  }

  // ------ BIRTH OF BOKI (PUBLIC SALE)
  function bokiBirth(
    uint256 _quantity,
    uint256 _nonce,
    bytes memory _signature
  ) external payable callerIsUser {
    require(saleStatus == SaleStatus.PUBLIC || saleStatus == SaleStatus.FINAL, "BIRTH OF BOKI IS NOT ON");
    require(saleStatus == SaleStatus.FINAL || publicBokiRemaining - _quantity >= 0, "PUBLIC CAP EXCEEDED");
    require(_quantity <= PUBLIC_BOKI_PER_TXN_LIMIT, "QUANTITY SURPASSES PER-TXN LIMIT");
    validateSignature(msg.sender, _nonce, _signature);

    publicBokiRemaining -= _quantity;
    processMint(_quantity);
  }

  // ------ EDIT CHAINLINK CONFIG
  function setChainlinkConfig(uint256 _fee, bytes32 _keyhash) external onlyOwner {
    chainlinkFee = _fee;
    chainlinkKeyHash = _keyhash;
  }

  // ------ REQUEST TOKEN OFFSET
  // NOTE: contract must be approved for and own 2 LINK before calling this function
  function startReveal(string memory _newURI) external onlyOwner returns (bytes32 requestId) {
    require(!revealed, "ALREADY REVEALED");
    postRevealBaseURI = _newURI;
    LINK.transferFrom(msg.sender, address(this), chainlinkFee);
    return requestRandomness(chainlinkKeyHash, chainlinkFee);
  }

  // ------ CHAINLINK CALLBACK FOR TOKEN OFFSET
  function fulfillRandomness(bytes32, uint256 _randomness) internal override {
    require(!revealed, "ALREADY REVEALED");
    revealed = true;
    tokenOffset = _randomness % totalSupply();
  }

  // ------ WITHDRAW FUNDS
  function withdrawFunds() external onlyOwner {
    payable(withdrawalAddress).transfer(address(this).balance);
  }

  // ------ SET PUBLIC KEY OF PUBLIC MINT SIGNATURE SIGNER
  function setPublicMintSigner(address _signer) external onlyOwner {
    publicMintSigner = _signer;
  }

  // ------ VERIFY SIGNATURE
  function validateSignature(
    address _sender,
    uint256 _nonce,
    bytes memory _signature
  ) internal {
    bytes32 signedHash = keccak256(abi.encodePacked(_sender, _nonce)).toEthSignedMessageHash();
    require(!signaturesUsed[_signature], "SIGNATURE ALREADY USED");
    require(signedHash.recover(_signature) == publicMintSigner, "NOT FROM BOKI FRONTEND");
    signaturesUsed[_signature] = true;
  }

  function numberMinted(address _owner) public view returns (uint256) {
    return _numberMinted(_owner);
  }

  function getOwnershipData(uint256 _tokenId) external view returns (TokenOwnership memory) {
    return _ownershipOf(_tokenId);
  }
}