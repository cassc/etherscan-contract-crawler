// SPDX-License-Identifier: None
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

struct SaleConfig {
  uint32 startTime;
  uint32 endTime;
  uint32 supplyLimit;
  uint128 mintPrice;
}

contract MongrelBreedingProgram is Ownable, ERC721A, ERC2981, PaymentSplitter {
  using SafeCast for uint256;
  using ECDSA for bytes32;

  // EVENTS *****************************************************

  event MintSignerUpdated();
  event RoyaltiesUpdated();
  event BaseUriUpdated();
  event PresaleConfigUpdated();
  event PublicSaleConfigUpdated();

  // ERRORS *****************************************************

  error SaleNotActive();
  error SignerNotSet();
  error InvalidAddress();
  error InvalidTime();
  error InvalidSignature();
  error IncorrectPayment();
  error MintLimitExceeded();
  error ZeroBalance();
  error OutOfSupply();

  // Storage *****************************************************

  SaleConfig public allowlistConfig;
  SaleConfig public publicSaleConfig;
  uint256 public constant MINT_LIMIT = 5;

  string public baseURI;
  address public mintSigner;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("allowlist(address buyer,uint256 limit)");

  address[] private _payees = [
    0xc33e74E72882C16ab90d115F13EEdB0E841f3150,
    0x3144A7A382c0389162C94AC8EF0671b106f9D2DD,
    0x7c792b98dA14Af2Ddc29Dd362B978A3610b2F3F0
  ];

  uint256[] private _shares = [81, 15, 4];

  // Constructor *****************************************************

  constructor() ERC721A("Mongrel Breeding Program", "MONGREL") PaymentSplitter(_payees, _shares) {
    allowlistConfig = SaleConfig({
      startTime: 1662681600, // Fri Sep 09 2022 00:00:00 GMT+0000
      endTime: 1662854400, // Sun Sep 11 2022 00:00:00 GMT+0000
      supplyLimit: 4805,
      mintPrice: 0.03 ether
    });

    publicSaleConfig = SaleConfig({
      startTime: 1662854400, // Sun Sep 11 2022 00:00:00 GMT+0000
      endTime: 1663286400, // Fri Sep 16 2022 00:00:00 GMT+0000
      supplyLimit: 5555,
      mintPrice: 0.05 ether
    });

    _setDefaultRoyalty(0xc33e74E72882C16ab90d115F13EEdB0E841f3150, 750); // 7.5% royalties

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("MongrelBreedingProgram")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  // Public Methods *****************************************************

  function allowlistMint(
    bytes memory signature,
    uint64 numberOfTokens,
    uint256 approvedLimit
  ) external payable {
    SaleConfig memory _saleConfig = allowlistConfig;

    if (block.timestamp < _saleConfig.startTime || block.timestamp > _saleConfig.endTime) revert SaleNotActive();

    if ((totalSupply() + numberOfTokens) > _saleConfig.supplyLimit) revert OutOfSupply();

    if (mintSigner == address(0)) revert SignerNotSet();

    if (msg.value < (_saleConfig.mintPrice * numberOfTokens)) revert IncorrectPayment();

    if ((_numberMinted(msg.sender) + numberOfTokens) > approvedLimit) revert MintLimitExceeded();

    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(TYPEHASH, msg.sender, approvedLimit))));

    address signer = digest.recover(signature);

    if (signer == address(0) || signer != mintSigner) revert InvalidSignature();

    _mint(msg.sender, numberOfTokens);
  }

  function publicMint(uint256 numberOfTokens) external payable {
    SaleConfig memory _saleConfig = publicSaleConfig;

    if (block.timestamp < _saleConfig.startTime || block.timestamp > _saleConfig.endTime) revert SaleNotActive();
    if (msg.value < (_saleConfig.mintPrice * numberOfTokens)) revert IncorrectPayment();

    if ((_numberMinted(msg.sender) + numberOfTokens) > MINT_LIMIT) revert MintLimitExceeded();

    if ((totalSupply() + numberOfTokens) > _saleConfig.supplyLimit) revert OutOfSupply();

    _mint(msg.sender, numberOfTokens);
  }

  function withdraw() external {
    if (address(this).balance == 0) revert ZeroBalance();

    for (uint256 i = 0; i < _payees.length; i++) {
      release(payable(payee(i)));
    }
  }

  // Owner Methods *****************************************************

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

  function configureAllowlist(
    uint32 startTime,
    uint32 endTime,
    uint32 supplyLimit,
    uint128 mintPrice
  ) external onlyOwner {
    if (0 == startTime || startTime > endTime) revert InvalidTime();

    emit PresaleConfigUpdated();
    allowlistConfig = SaleConfig({ startTime: startTime, endTime: endTime, supplyLimit: supplyLimit, mintPrice: mintPrice });
  }

  function configurePublicSale(
    uint32 startTime,
    uint32 endTime,
    uint32 supplyLimit,
    uint128 mintPrice
  ) external onlyOwner {
    if (allowlistConfig.endTime > startTime || startTime > endTime) revert InvalidTime();

    emit PublicSaleConfigUpdated();
    publicSaleConfig = SaleConfig({ startTime: startTime, endTime: endTime, supplyLimit: supplyLimit, mintPrice: mintPrice });
  }

  function ownerMint(address to, uint256 numberOfTokens) external onlyOwner {
    if ((totalSupply() + numberOfTokens) > publicSaleConfig.supplyLimit) revert OutOfSupply();

    _mint(to, numberOfTokens);
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