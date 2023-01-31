// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BottzArmy is ERC721A, Ownable, AccessControl, ReentrancyGuard {
  event Mint(uint256 mintType, uint256 tokenStart, uint256 tokenEnd);

  using Strings for uint256;

  uint256 private constant maxSupply = 5000;
  uint256 public maxSupplyCaptains = 600;
  uint256 public maxSupplyMajors = 300;
  uint256 public maxSupplyGenerals = 100;
  uint256 public maxSupplyTotal = 5000;
  uint256 public captainsMinted = 0;
  uint256 public majorsMinted = 0;
  uint256 public generalsMinted = 0;
  uint256 public captainsPrice = 0.07 ether;
  uint256 public majorsPrice = 0.175 ether;
  uint256 public generalsPrice = 0.35 ether;
  uint256 public maxPerWalletPaid = 3;
  uint256 public maxPerWalletFree = 3;
  bool public isTransferPaused = false;
  bool public isMintPaused = true;
  bool public captainsStarted = true;
  bool public majorsStarted = true;
  bool public generalsStarted = true;
  bool public privatesStarted = false;
  bool private isRevealed = false;
  string private uriPrefix;
  string private hiddenMetadataURI;
  bytes32 public merkleRoot;
  address private withdrawWallet;
  mapping(address => uint256) public paidMinted;
  mapping(address => uint256) public freeMinted;

  constructor() ERC721A("BOTTZ Army", "BOTT") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "No data exists for provided tokenId.");

    if (isRevealed == false) {
      return hiddenMetadataURI;
    }

    return bytes(uriPrefix).length > 0 ? string(abi.encodePacked(uriPrefix, tokenId.toString(), ".json")) : "";
  }

  function mintedByCallerPaid() public view returns (uint256) {
    return paidMinted[_msgSender()];
  }

  modifier mintCompliance(
    bool isStarted,
    uint256 price,
    uint256 mintAmount
  ) {
    require(!isMintPaused, "Minting is paused.");
    require(isStarted, "This sale is paused.");
    require(msg.value >= (price * mintAmount), "Insufficient balance to mint.");
    require(
      (mintedByCallerPaid() + mintAmount) <= maxPerWalletPaid,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );
    _;
  }

  modifier whitelistCompliance(bytes32[] calldata merkleProof) {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof, this wallet is not allowed to mint.");
    _;
  }

  function mintPaid(uint256 mintAmount, uint256 mintType) internal {
    uint256 tokenStart = totalSupply();

    paidMinted[_msgSender()] = mintedByCallerPaid() + mintAmount;

    _safeMint(_msgSender(), mintAmount);

    uint256 tokenEnd = totalSupply();

    emit Mint(mintType, tokenStart, tokenEnd);
  }

  function captainsMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    external
    payable
    mintCompliance(captainsStarted, captainsPrice, _mintAmount)
    whitelistCompliance(_merkleProof)
  {
    require((captainsMinted + _mintAmount) <= maxSupplyCaptains, "Mint amount exceeds allocated supply of Captains.");

    mintPaid(_mintAmount, 1);

    captainsMinted += _mintAmount;
  }

  function majorsMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    external
    payable
    mintCompliance(majorsStarted, majorsPrice, _mintAmount)
    whitelistCompliance(_merkleProof)
  {
    require((majorsMinted + _mintAmount) <= maxSupplyMajors, "Mint amount exceeds allocated supply of Majors.");

    mintPaid(_mintAmount, 2);

    majorsMinted += _mintAmount;
  }

  function generalsMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    external
    payable
    mintCompliance(generalsStarted, generalsPrice, _mintAmount)
    whitelistCompliance(_merkleProof)
  {
    require((generalsMinted + _mintAmount) <= maxSupplyGenerals, "Mint amount exceeds allocated supply of Generals.");

    mintPaid(_mintAmount, 3);

    generalsMinted += _mintAmount;
  }

  function privatesMint(uint256 _mintAmount) external payable {
    uint256 minted = freeMinted[_msgSender()];

    require(!isMintPaused, "Minting is paused.");
    require(privatesStarted, "Privates sale is paused.");
    require(
      (minted + _mintAmount) <= maxPerWalletFree,
      "Selected number of mints will exceed the maximum amount of allowed per wallet."
    );
    require((totalSupply() + _mintAmount) <= maxSupplyTotal, "Mint amount exceeds allocated supply.");

    freeMinted[_msgSender()] = minted + _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  // admin
  function mintFor(
    uint256 _mintAmount,
    address _receiver,
    uint256 _mintType
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 tokenStart = totalSupply();

    require((totalSupply() + _mintAmount) <= maxSupplyTotal, "Mint amount exceeds allocated supply.");

    if (_mintType == 1) {
      require((captainsMinted + _mintAmount) <= maxSupplyCaptains, "Mint amount exceeds allocated supply.");

      captainsMinted += _mintAmount;
    } else if (_mintType == 2) {
      require((majorsMinted + _mintAmount) <= maxSupplyMajors, "Mint amount exceeds allocated supply.");

      majorsMinted += _mintAmount;
    } else if (_mintType == 3) {
      require((generalsMinted + _mintAmount) <= maxSupplyGenerals, "Mint amount exceeds allocated supply.");

      generalsMinted += _mintAmount;
    }

    _safeMint(_receiver, _mintAmount);

    uint256 tokenEnd = totalSupply();

    emit Mint(_mintType, tokenStart, tokenEnd);
  }

  function updateMaxSupplyTotal(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // collection can be capped, if needed, but can never increase from initial total
    require(_number <= maxSupply, "Public supply can not exceed total defined.");
    require(_number >= totalSupply(), "Supply can not be less than already minted.");

    maxSupplyTotal = _number;
  }

  function updateCaptainsPrice(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    captainsPrice = _number;
  }

  function updateMajorsPrice(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    majorsPrice = _number;
  }

  function updateGeneralsPrice(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    generalsPrice = _number;
  }

  function updateMaxPerWalletPaid(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxPerWalletPaid = _number;
  }

  function updateMaxPerWalletFree(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxPerWalletFree = _number;
  }

  function toggleTransfer(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isTransferPaused = _state;
  }

  function toggleMint(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isMintPaused = _state;
  }

  function toggleCaptainsSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    captainsStarted = _state;
  }

  function toggleMajorsSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    majorsStarted = _state;
  }

  function toggleGeneralsSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    generalsStarted = _state;
  }

  function togglePrivatesSale(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    privatesStarted = _state;
  }

  function reveal() external onlyRole(DEFAULT_ADMIN_ROLE) {
    isRevealed = true;
  }

  function updateURIPrefix(string calldata _uriPrefix) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uriPrefix = _uriPrefix;
  }

  function updateHiddenMetadataURI(string memory _hiddenMetadataURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    hiddenMetadataURI = _hiddenMetadataURI;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    merkleRoot = _merkleRoot;
  }

  function updateWithdrawWallet(address _withdrawWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
    withdrawWallet = _withdrawWallet;
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    require(withdrawWallet != address(0), "withdraw wallet is not set.");

    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }
}