// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {Initializable, ONFT721AUpgradeable, IERC721AUpgradeable} from "./contracts-upgradeable/token/onft/ERC721/ONFT721AUpgradeable.sol";
import "./interfaces/IDelegationRegistry.sol";

/**
 * @title UtilityWenUpgradeable
 * @notice Wen is a neW kind of NFT
 * @author @Utility_wen
 */
contract UtilityWenUpgradeable is Initializable, ONFT721AUpgradeable, Proxied {
  /// @notice Maximum supply for the collection
  uint public maxSupply; // n-1

  /// @dev Treasury
  address public treasury;

  /// @notice Public mint
  bool public isPublicOpen;

  /// @dev The max per wallet (n-1)
  uint public maxPerWallet;

  /// @notice ETH mint price
  uint public price;

  /// @notice Live timestamp
  uint public liveAt;

  /// @notice Expires timestamp
  uint public expiresAt;

  /// @notice Guaranteed merkle root
  bytes32 guaranteedMerkleRoot;

  /// @notice Whitelist merkle root
  bytes32 whitelistMerkleRoot;

  /// @notice An address mapping mints
  mapping(address => uint) public addressToMinted;

  modifier isLive() {
    require(isMintLive(), "!live");
    _;
  }

  modifier isDelegate(address vault) {
    bool isDelegateValid = IDelegationRegistry(delegationRegistryAddress)
      .checkDelegateForContract(_msgSender(), vault, address(this));
    require(isDelegateValid, "!invalid");
    _;
  }

  modifier withinThreshold(uint _amount) {
    require(totalSupply() + _amount < maxSupply, "!mintable");
    require(
      addressToMinted[_msgSenderERC721A()] + _amount < maxPerWallet,
      "!able"
    );
    _;
  }

  modifier isWhitelisted(bytes32 _merkleRoot, bytes32[] calldata _proof) {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSenderERC721A()));
    require(MerkleProofUpgradeable.verify(_proof, _merkleRoot, leaf), "!valid");
    _;
  }

  modifier isCorrectPrice(uint _amount, uint _price) {
    require(msg.value >= _amount * _price, "!funds");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string memory _name,
    string memory _symbol,
    string memory baseURI_,
    address _delegationRegistryAddress,
    uint _minGasToTransfer,
    address _lzEndpoint
  ) public initializer {
    __ONFT721AUpgradeable_init(
      _name,
      _symbol,
      baseURI_,
      _minGasToTransfer,
      _lzEndpoint
    );

    // Set base treasury to deployer
    treasury = payable(_msgSender());

    // Mint setup
    maxSupply = 10001;
    price = 0.051 ether;
    liveAt = 1687615200;
    expiresAt = 1687701601;
    maxPerWallet = 6;
    isPublicOpen = false;
  }

  /**
   * @dev Guarantee mint function
   * @param _amount The amount of nfts to mint
   * @param _proof The merkle proof for whitelist check
   */
  function guaranteedMint(uint _amount, bytes32[] calldata _proof)
    external
    payable
    isLive
    isCorrectPrice(_amount, price)
    isWhitelisted(guaranteedMerkleRoot, _proof)
    withinThreshold(_amount)
  {
    _processMint(_msgSenderERC721A(), _amount);
  }

  /**
   * @dev Guarantee mint function
   * @param _amount The amount of nfts to mint
   * @param _proof The merkle proof for whitelist check
   */
  function whitelistMint(uint _amount, bytes32[] calldata _proof)
    external
    payable
    isLive
    isCorrectPrice(_amount, price)
    isWhitelisted(whitelistMerkleRoot, _proof)
    withinThreshold(_amount)
  {
    _processMint(_msgSenderERC721A(), _amount);
  }

  /**
   * @dev Public mint function
   * @param _amount The amount to mint
   */
  function mint(uint _amount)
    external
    payable
    isLive
    isCorrectPrice(_amount, price)
    withinThreshold(_amount)
  {
    require(isPublicOpen, "!public");
    _processMint(_msgSenderERC721A(), _amount);
  }

  /**
   * @dev Process minting
   * @param _to The address to associate
   * @param _amount The amount to mint
   */
  function _processMint(address _to, uint _amount) internal {
    addressToMinted[_to] += _amount;
    _mint(_to, _amount);
  }

  /// @dev Check if mint is live
  function isMintLive() public view returns (bool) {
    return block.timestamp >= liveAt && block.timestamp <= expiresAt;
  }

  /**
   * @notice Sets the collection max supply
   * @param _maxSupply The max supply of the collection
   */
  function setMaxSupply(uint _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  /**
   * @notice Sets whether public minting is open
   * @param _isPublicOpen boolean for public open state
   */
  function setPublicOpen(bool _isPublicOpen) external onlyOwner {
    isPublicOpen = _isPublicOpen;
  }

  /**
   * @notice Sets timestamps for live and expires timeframe
   * @param _liveAt A unix timestamp for live date
   * @param _expiresAt A unix timestamp for expiration date
   */
  function setMintWindow(uint _liveAt, uint _expiresAt) external onlyOwner {
    liveAt = _liveAt;
    expiresAt = _expiresAt;
  }

  /**
   * @notice Sets the collection max per wallet
   * @param _maxPerWallet The max per wallet
   */
  function setMaxPerWallet(uint _maxPerWallet) external onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  /**
   * @notice Sets eth price
   * @param _price The price in wei
   */
  function setPrice(uint _price) external onlyOwner {
    price = _price;
  }

  /**
   * @notice Sets the treasury recipient
   * @param _treasury The treasury address
   */
  function setTreasury(address _treasury) public onlyOwner {
    treasury = payable(_treasury);
  }

  /**
   * @notice Sets the guaranteed merkle root for the mint
   * @param _guaranteedMerkleRoot The merkle root to set
   */
  function setGuaranteedMerkleRoot(bytes32 _guaranteedMerkleRoot)
    external
    onlyOwner
  {
    guaranteedMerkleRoot = _guaranteedMerkleRoot;
  }

  /**
   * @notice Sets the whitelist merkle root for the mint
   * @param _whitelistMerkleRoot The merkle root to set
   */
  function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
    external
    onlyOwner
  {
    whitelistMerkleRoot = _whitelistMerkleRoot;
  }

  /// @notice Withdraws funds from contract
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    (bool success, ) = treasury.call{value: balance}("");
    require(success, "!withdraw");
  }

  /**
   * @dev Airdrop function
   * @param _to The address to mint to
   * @param _amount The amount to mint
   */
  function airdrop(address _to, uint _amount) external onlyOwner {
    require(totalSupply() + _amount < maxSupply, "!enough");
    _mint(_to, _amount);
  }

  /// @notice Withdraws NFTs from contract
  function withdrawNFTAssets(uint[] calldata tokenIds) public onlyOwner {
    for (uint i; i < tokenIds.length; i++) {
      IERC721AUpgradeable(address(this)).transferFrom(
        address(this),
        _msgSenderERC721A(),
        tokenIds[i]
      );
    }
  }
}