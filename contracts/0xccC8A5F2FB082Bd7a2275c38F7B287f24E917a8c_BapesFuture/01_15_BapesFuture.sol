// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IBapesTokens is IERC721 {
  function getOwnerTokens(address _owner) external view returns (uint256[] memory);

  function burn(uint256 _amount, address _address) external returns (bool);
}

contract BapesFuture is ERC721A, Ownable, AccessControl, ReentrancyGuard {
  using Strings for uint256;

  uint256 private constant maxSupply = 10000;
  uint256 private maxSupplyTotal = 10000;
  uint256 private constant pcPrice = 0.1 ether;
  uint256 private constant bgkPrice = 0.15 ether;
  uint256 private constant wlPrice = 0.2 ether;
  uint256 private constant publicPrice = 0.25 ether;
  uint256 private constant maxPerTx = 100;
  uint256 private maxPerWallet = 100;
  bool public paused = false;
  bool public pcStarted = false;
  bool public bgkStarted = false;
  bool public wlStarted = false;
  bool public publicStarted = false;
  bool private revealed = false;
  string private uriPrefix;
  string private hiddenMetadataURI;
  bytes32 public merkleRoot;
  address private withdrawWallet;
  mapping(address => uint256) private mintedWallets;
  mapping(address => mapping(uint256 => bool)) private tokensUsed;

  IBapesTokens private pc;
  IBapesTokens private bgk;

  constructor(string memory _hiddenMetadataURI) ERC721A("BapesFuture", "FUTURE") {
    pc = IBapesTokens(0x5659eD70A0cEDFD6e9A2f132dC37847D8b34E525);
    bgk = IBapesTokens(0x3A472c4D0dfbbb91ed050d3bb6B3623037c6263c);

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    setHiddenMetadataURI(_hiddenMetadataURI);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    _mintCompliance(_mintAmount);
    _;
  }

  function _mintCompliance(uint256 _mintAmount) private view {
    require(!paused, "Minting is paused.");
    require(_mintAmount <= maxPerTx, "Mint amount exceeds max per transaction.");
    require((totalSupply() + _mintAmount) <= maxSupplyTotal, "Mint amount exceeds total supply.");
  }

  function increment(uint256 _i) private pure returns (uint256) {
    unchecked {
      return _i + 1;
    }
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "No data exists for provided tokenId.");

    if (revealed == false) {
      return hiddenMetadataURI;
    }

    return bytes(uriPrefix).length > 0 ? string(abi.encodePacked(uriPrefix, tokenId.toString(), ".json")) : "";
  }

  function pcMint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) {
    require(pcStarted, "Parental Certificate sale is paused.");
    require(msg.value >= (pcPrice * _mintAmount), "Insufficient balance to mint.");

    pc.burn(_mintAmount, _msgSender());

    _safeMint(_msgSender(), _mintAmount);
  }

  function bgkMint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) {
    require(bgkStarted, "Bapes Genesis Key sale is paused.");
    require(msg.value >= (bgkPrice * _mintAmount), "Insufficient balance to mint.");
    require(
      _mintAmount <= bgk.balanceOf(_msgSender()),
      "You do not have enough BGKs to mint selected amount of tokens."
    );

    uint256[] memory ownerTokens = bgk.getOwnerTokens(_msgSender());
    uint256 length = ownerTokens.length;
    uint256 unused = 0;

    for (uint256 i = 0; i < length; i++) {
      uint256 el = ownerTokens[i];

      if (!tokensUsed[address(bgk)][el]) {
        tokensUsed[address(bgk)][el] = true;

        unused++;
      }

      if (unused == _mintAmount) {
        break;
      }
    }

    require(unused >= _mintAmount, "You do not have enough unused BGKs to mint selected amount of tokens.");

    _safeMint(_msgSender(), _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    external
    payable
    mintCompliance(_mintAmount)
  {
    uint256 minted = mintedWallets[_msgSender()];

    require(wlStarted, "Whitelist sale is paused.");
    require(msg.value >= (wlPrice * _mintAmount), "Insufficient balance to mint.");
    require(
      (minted + _mintAmount) <= maxPerWallet,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof, this wallet is not whitelisted.");

    mintedWallets[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function publicMint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) {
    require(publicStarted, "Public sale is paused.");
    require(msg.value >= publicPrice * _mintAmount, "Insufficient balance to mint.");

    _safeMint(_msgSender(), _mintAmount);
  }

  function getBalanceOf(address _wallet) external view returns (uint256) {
    return mintedWallets[_wallet];
  }

  function isBgkUsed(uint256 tokenId) external view returns (bool) {
    return tokensUsed[address(bgk)][tokenId];
  }

  function isPCUsed(uint256 tokenId) external view returns (bool) {
    return tokensUsed[address(pc)][tokenId];
  }

  // admin
  function setHiddenMetadataURI(string memory _hiddenMetadataURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    hiddenMetadataURI = _hiddenMetadataURI;
  }

  function mintFor(uint256 _mintAmount, address _receiver)
    external
    mintCompliance(_mintAmount)
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _safeMint(_receiver, _mintAmount);
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    require(withdrawWallet != address(0), "withdraw wallet is not set.");

    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }

  function updateWithdrawWallet(address _withdrawWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
    withdrawWallet = _withdrawWallet;
  }

  function updateMaxSupplyTotal(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // collection can be capped, if needed, but can never increase from initial total
    require(_number <= maxSupply, "Public supply can not exceed total defined.");

    maxSupplyTotal = _number;
  }

  function updateMaxPerWallet(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxPerWallet = _number;
  }

  function updateURIPrefix(string calldata _uriPrefix) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uriPrefix = _uriPrefix;
  }

  function reveal() external onlyRole(DEFAULT_ADMIN_ROLE) {
    revealed = true;
  }

  function togglePause(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    paused = _state;
  }

  function togglePCSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    pcStarted = _state;
  }

  function toggleBGKSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    bgkStarted = _state;
  }

  function toggleWhitelistSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    wlStarted = _state;
  }

  function togglePublicSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    publicStarted = _state;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    merkleRoot = _merkleRoot;
  }
}