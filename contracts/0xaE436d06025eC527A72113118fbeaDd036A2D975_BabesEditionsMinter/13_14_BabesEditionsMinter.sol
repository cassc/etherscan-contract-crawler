// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IBabes.sol";

struct MintConfig {
  uint8 accountMintLimit;
  uint8 mintCounter;
  uint32 mintStartTime;
  uint96 holdersMintPrice;
  uint96 publicMintPrice;
}

/// @title Babes Editions Minter
/// @notice Minter contract for Alunaverse NFT collection, supports ECDSA Signature based whitelist minting, and public access minting.
contract BabesEditionsMinter is Ownable, PaymentSplitter {
  using ECDSA for bytes32;

  // EVENTS *****************************************************

  event ConfigUpdated(bytes32 config, bytes value);
  event ConfigLocked(bytes32 config);

  // ERRORS *****************************************************

  error InvalidConfig(bytes32 config);
  error ConfigIsLocked(bytes32 config);
  error NoMintSigner();
  error InvalidSignature();
  error InsufficientPayment();
  error MintLimitExceeded();
  error HolderOnly();
  error MintNotActive();
  error OutOfSupply();
  error ZeroBalance();
  error WithdrawalFailed();

  // Storage *****************************************************

  // Public ****************************

  /// @dev The Babes ERC721 contract
  IBabes public Babes;

  /// @dev The Encryptas ERC721 contract
  IERC721 public Encryptas;

  /// @dev only 51 babes can be minted through this contract
  uint256 public constant TOKEN_LIMIT = 51;

  /// @dev config data for this mint contract
  MintConfig public mintConfig;

  /// @dev Keeps track of how many of each token a wallet has minted for enforcing mint limit
  mapping(address => uint256) public minted;

  /// @dev The public address of the authorized signer used to create the holder mint signature
  address public mintSigner;

  // Private ****************************

  // Used internally for randomized minting
  mapping(uint256 => uint256) private randoms;

  // Tracks which config items are locked permanently and unable to be updated
  mapping(bytes32 => bool) private configLocked;

  /// @dev used for decoding the holder mint signature
  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("holderMint(address buyer)");

  address[] private mintPayees = [
    0x19461698453e26b98ceE5B984e1a86e13C0f68Be,
    0xF23296337d45DA62e34ceDbc80db478bda3cAF9b
  ];

  uint256[] private mintShares = [1, 1];

  // Constructor *****************************************************

  constructor(address babesAddress, address encryptasAddress) PaymentSplitter(mintPayees, mintShares) {
    Babes = IBabes(babesAddress);
    Encryptas = IERC721(encryptasAddress);

    mintConfig = MintConfig({
      accountMintLimit: 5, // 5 mints per wallet
      mintCounter: 0,
      mintStartTime: 1677333600, // Sat Feb 25 2023 14:00:00 GMT+0000
      holdersMintPrice: 0.066 ether,
      publicMintPrice: 0.099 ether
    });

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("BabesEditionsMinter")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  // Owner Methods *****************************************************

  function updateConfig(bytes32 config, bytes calldata value) external onlyOwner {
    if (configLocked[config]) revert ConfigIsLocked(config);

    if (config == "holder") mintConfig.holdersMintPrice = abi.decode(value, (uint96));
    else if (config == "public") mintConfig.publicMintPrice = abi.decode(value, (uint96));
    else if (config == "start") mintConfig.mintStartTime = abi.decode(value, (uint32));
    else if (config == "limit") mintConfig.accountMintLimit = abi.decode(value, (uint8));
    else if (config == "signer") mintSigner = abi.decode(value, (address));
    else revert InvalidConfig(config);

    emit ConfigUpdated(config, value);
  }

  function lockConfig(bytes32 config) external onlyOwner {
    configLocked[config] = true;

    emit ConfigLocked(config);
  }

  /// @notice Allows the contract owner to withdraw the current balance stored in this contract into withdrawalAddress
  function withdraw() external onlyOwner {
    if (address(this).balance == 0) revert ZeroBalance();

    for (uint256 i = 0; i < mintPayees.length; i++) {
      release(payable(payee(i)));
    }
  }

  // Public Methods *****************************************************

  /// @notice Function for holders of 101Babes or Encryptas to mint
  /// @dev 101Babes holders verified through offchain process via mintSigner
  /// @param signature The signature produced by the mintSigner to validate that the recipient is a 101Babes holder
  /// @param to The address to mint to
  /// @param amount The number of tokens to mint
  function holderMint(bytes memory signature, address to, uint256 amount) external payable {
    if (Encryptas.balanceOf(to) == 0) {
      if (signature.length == 0) revert HolderOnly();

      if (mintSigner == address(0)) revert NoMintSigner();

      bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(TYPEHASH, to))));
      address signer = digest.recover(signature);

      if (signer != mintSigner) revert InvalidSignature();
    }

    if (msg.value < (mintConfig.holdersMintPrice * amount)) revert InsufficientPayment();

    mint(to, amount);
  }

  /// @notice Function for anyone to mint
  /// @param to The address to mint to
  /// @param amount The number of tokens to mint
  function publicMint(address to, uint256 amount) external payable {
    if (msg.value < (mintConfig.publicMintPrice * amount)) revert InsufficientPayment();

    mint(to, amount);
  }

  // Private Methods *****************************************************

  function mint(address to, uint256 amount) private {
    MintConfig memory _config = mintConfig;

    if ((minted[to] + amount) > _config.accountMintLimit) revert MintLimitExceeded();
    minted[to] += amount;

    if ((_config.mintCounter + amount) > TOKEN_LIMIT) revert OutOfSupply();

    if (block.timestamp < _config.mintStartTime) revert MintNotActive();

    uint256[] memory randomTokenIds = new uint256[](amount);

    for (uint256 i = 0; i < amount; ) {
      // Pick a random allocation using Fisher-Yates shuffle
      uint256 boundary;

      unchecked {
        boundary = TOKEN_LIMIT - _config.mintCounter++;
      }

      uint256 rand = getRandomNumber(boundary);

      randomTokenIds[i] = ((randoms[rand] == 0) ? rand : randoms[rand]) + 49; // BABES Limited Editions mint starts from token #50

      randoms[rand] = randoms[boundary] == 0 ? boundary : randoms[boundary];

      unchecked {
        ++i;
      }
    }

    mintConfig.mintCounter = _config.mintCounter;

    Babes.mint(to, randomTokenIds);
  }

  /// @dev Returns a pseudo random number between 1 and max
  function getRandomNumber(uint256 max) private view returns (uint256) {
    uint256 number = uint256(
      keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase, block.timestamp, max))
    );

    return (number % max) + 1;
  }
}