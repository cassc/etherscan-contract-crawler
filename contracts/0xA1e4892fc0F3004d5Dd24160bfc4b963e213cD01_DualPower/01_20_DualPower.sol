// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@paperxyz/contracts/keyManager/IPaperKeyManager.sol";
import "erc721a/contracts/ERC721A.sol";

// DualPower by LNMH LLC

struct MintConfig {
  uint32 allowlistMintTime;
  uint32 publicMintTime;
  uint32 mintEndTime;
  uint32 supplyLimit;
  uint96 mintPrice;
  uint8 allowlistMintLimit;
  uint8 publicMintLimit;
}

contract DualPower is Ownable, ERC721A, ERC2981, PaymentSplitter {
  using ECDSA for bytes32;

  // EVENTS *****************************************************

  event MintSignerUpdated();
  event RoyaltiesUpdated();
  event BaseUriUpdated();
  event MintConfigUpdated();

  // ERRORS *****************************************************

  error MintNotActive();
  error IncorrectPayment();
  error SignerNotSet();
  error InvalidAddress();
  error InvalidTime();
  error InvalidSignature();
  error CannotRegisterPaperKey();
  error MintLimitExceeded();
  error OutOfSupply();
  error ZeroBalance();
  error WithdrawFailed();

  // Storage *****************************************************

  MintConfig public mintConfig;

  string public baseURI = "ipfs://QmerXcycYJcLHBi1HVszvkT5uDpkKLmPSUfbpKps3Pv9QG/";
  address public mintSigner;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("mint(address buyer)");

  IPaperKeyManager paperKeyManager;

  address[] private _payees = [0xce737fB7ba93E2bA0DBD485D0762641cf6A1B567, 0x7c792b98dA14Af2Ddc29Dd362B978A3610b2F3F0];

  uint256[] private _shares = [95, 5];

  // Constructor *****************************************************

  constructor(address _paperKeyManagerAddress) ERC721A("DualPower", "DP") PaymentSplitter(_payees, _shares) {
    paperKeyManager = IPaperKeyManager(_paperKeyManagerAddress);

    mintConfig = MintConfig({
      allowlistMintTime: 1668996000, // Mon Nov 21 2022 02:00:00 GMT+0000
      publicMintTime: 1669082400, // Tue Nov 22 2022 02:00:00 GMT+0000
      mintEndTime: 1669687200, // Tue Nov 29 2022 02:00:00 GMT+0000
      supplyLimit: 3133,
      mintPrice: 0.1 ether,
      allowlistMintLimit: 2,
      publicMintLimit: 2
    });

    _setDefaultRoyalty(0xce737fB7ba93E2bA0DBD485D0762641cf6A1B567, 1000); // 10% royalties

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("DualPower")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  // Modifiers **********************************************************

  modifier onlyPaper(
    bytes32 _hash,
    bytes32 _nonce,
    bytes calldata _signature
  ) {
    bool success = paperKeyManager.verify(_hash, _nonce, _signature);
    if (!success) revert InvalidSignature();
    _;
  }

  // Public Methods *****************************************************

  /**
   * @notice  Allows paper.xyz to check a user's mint eligibility based on the current time.
   * @param   recipient user's wallet address.
   * @param   amount number of NFTs to mint.
   * @param   allowlist true for checking allowlist mint eligibility, false for public sale.
   * @return  string empty if eligible, error message if not.
   */
  function checkMintEligibility(
    address recipient,
    uint64 amount,
    bool allowlist
  ) public view returns (string memory) {
    if (
      (block.timestamp < (allowlist ? mintConfig.allowlistMintTime : mintConfig.publicMintTime)) ||
      (block.timestamp > (allowlist ? mintConfig.publicMintTime : mintConfig.mintEndTime))
    ) return "Sale not active";

    if (allowlist) {
      if ((_numberMinted(recipient) + amount) > mintConfig.allowlistMintLimit) return "Mint limit exceeded";
    } else {
      if ((_getAux(recipient) + amount) > mintConfig.publicMintLimit) return "Mint limit exceeded";
    }

    if ((totalSupply() + amount) > mintConfig.supplyLimit) return "Not enough supply";

    return "";
  }

  /**
   * @notice  Allows paper.xyz direct access to mint during allowlist.
   * @param   recipient user's wallet address.
   * @param   amount number of NFTs to mint.
   * @param   _nonce provided by paper.xyz.
   * @param   _signature provided by paper.xyz.
   */
  function paperAllowlistMint(
    address recipient,
    uint64 amount,
    bytes32 _nonce,
    bytes calldata _signature
  ) external payable onlyPaper(keccak256(abi.encode(recipient, amount)), _nonce, _signature) {
    MintConfig memory _mintConfig = mintConfig;

    if (block.timestamp < _mintConfig.allowlistMintTime || block.timestamp > _mintConfig.publicMintTime) revert MintNotActive();

    if ((_numberMinted(recipient) + amount) > _mintConfig.allowlistMintLimit) revert MintLimitExceeded();

    if (msg.value < amount * _mintConfig.mintPrice) revert IncorrectPayment();

    mint(recipient, amount);
  }

  function allowlistMint(
    bytes calldata signature,
    address recipient,
    uint64 amount
  ) external payable {
    MintConfig memory _mintConfig = mintConfig;

    if (block.timestamp < _mintConfig.allowlistMintTime || block.timestamp > _mintConfig.publicMintTime) revert MintNotActive();

    if (mintSigner == address(0)) revert SignerNotSet();

    if ((_numberMinted(recipient) + amount) > _mintConfig.allowlistMintLimit) revert MintLimitExceeded();

    if (msg.value < amount * _mintConfig.mintPrice) revert IncorrectPayment();

    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(TYPEHASH, recipient))));

    address signer = digest.recover(signature);

    if (signer == address(0) || signer != mintSigner) revert InvalidSignature();

    mint(recipient, amount);
  }

  function publicMint(address recipient, uint64 amount) external payable {
    MintConfig memory _mintConfig = mintConfig;

    if (block.timestamp < _mintConfig.publicMintTime || block.timestamp > _mintConfig.mintEndTime) revert MintNotActive();

    uint64 publicMinted = _getAux(recipient);
    if ((publicMinted + amount) > _mintConfig.publicMintLimit) revert MintLimitExceeded();

    if (msg.value < amount * _mintConfig.mintPrice) revert IncorrectPayment();

    _setAux(recipient, publicMinted + amount);

    mint(recipient, amount);
  }

  function withdraw() external {
    if (address(this).balance == 0) revert ZeroBalance();

    for (uint256 i = 0; i < _payees.length; i++) {
      release(payable(payee(i)));
    }
  }

  function withdrawToken(address tokenContract) external {
    if (address(this).balance == 0) revert ZeroBalance();

    for (uint256 i = 0; i < _payees.length; i++) {
      release(IERC20(tokenContract), payable(payee(i)));
    }
  }

  // Owner Methods *****************************************************

  function registerPaperKey(address _paperKey) external onlyOwner {
    bool success = paperKeyManager.register(_paperKey);

    if (!success) revert CannotRegisterPaperKey();
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    emit BaseUriUpdated();
    baseURI = newBaseUri;
  }

  function setMintSigner(address newSigner) external onlyOwner {
    emit MintSignerUpdated();
    mintSigner = newSigner;
  }

  function setRoyalties(address recipient, uint96 value) external onlyOwner {
    if (recipient == address(0)) revert InvalidAddress();

    emit RoyaltiesUpdated();
    _setDefaultRoyalty(recipient, value);
  }

  function configureMint(
    uint32 allowlistMintTime,
    uint32 publicMintTime,
    uint32 mintEndTime,
    uint32 supplyLimit,
    uint96 mintPrice,
    uint8 allowlistMintLimit,
    uint8 publicMintLimit
  ) external onlyOwner {
    if (0 == allowlistMintTime || allowlistMintTime > publicMintTime || publicMintTime > mintEndTime) revert InvalidTime();

    emit MintConfigUpdated();
    mintConfig = MintConfig({
      allowlistMintTime: allowlistMintTime,
      publicMintTime: publicMintTime,
      mintEndTime: mintEndTime,
      supplyLimit: supplyLimit,
      mintPrice: mintPrice,
      allowlistMintLimit: allowlistMintLimit,
      publicMintLimit: publicMintLimit
    });
  }

  function ownerMint(address to, uint256 amount) external onlyOwner {
    mint(to, amount);
  }

  // Private Methods *****************************************************

  function mint(address to, uint256 amount) private {
    if ((totalSupply() + amount) > mintConfig.supplyLimit) revert OutOfSupply();

    _mint(to, amount);
  }

  // Override Methods *****************************************************

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721A) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}