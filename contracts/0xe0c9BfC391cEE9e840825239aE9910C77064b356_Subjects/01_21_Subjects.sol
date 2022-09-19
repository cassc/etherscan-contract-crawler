// SPDX-License-Identifier: None
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "./ITether.sol";

contract Subjects is Ownable, ERC721A, ERC2981, PaymentSplitter {
  using SafeCast for uint256;
  using Strings for uint256;
  using ECDSA for bytes32;

  // ERRORS *****************************************************

  error NotActive();
  error SignerNotSet();
  error InvalidAddress();
  error InvalidTime();
  error InvalidSignature();
  error IncorrectPayment();
  error MintLimitExceeded();
  error ZeroBalance();
  error OutOfSupply();
  error OnlyTokenOwner();
  error AlreadyClaimed();
  error OnlyEOA();

  // Storage *****************************************************

  uint256 public SUPPLY_LIMIT = 7777;
  uint256 public MINT_PRICE = 0.089 ether;
  uint256 public PROJECT_D_LIMIT = 250;

  ITether public Tether;

  bool public mintActive;

  bool public projectDActive;
  uint256 public projectDCounter;
  uint256 public projectDPrice;
  mapping(uint256 => uint256) public projectDId;
  mapping(uint256 => uint256) projectDRandoms;

  string public baseURI;
  string public projectDBaseURI;

  address public mintSigner;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("mint(address buyer)");

  address[] private _payees = [0x6a4DadAd3aFff72Ab864C00eccA7650a60446D87, 0x76bf7b1e22C773754EBC608d92f71cc0B5D99d4B];

  uint256[] private _shares = [95, 5];

  // Constructor *****************************************************

  constructor() ERC721A("Subjects", "SUBJECT") PaymentSplitter(_payees, _shares) {
    _setDefaultRoyalty(address(this), 700); // 7% royalties

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("Subjects")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  // Public Methods *****************************************************

  function mintOne(bytes memory signature) external {
    if (!mintActive) revert NotActive();

    _onlyEOA(msg.sender);

    _firstTimeMint(msg.sender);

    _sufficientSupply(1);

    validateSignature(signature);

    _mint(msg.sender, 1);
  }

  function mintTwo(bytes memory signature) external payable {
    if (!mintActive) revert NotActive();

    _onlyEOA(msg.sender);

    _firstTimeMint(msg.sender);

    _sufficientSupply(2);

    validateSignature(signature);

    if (msg.value != MINT_PRICE) revert IncorrectPayment();

    _mint(msg.sender, 2);
  }

  function claimD(uint256 tokenId) external payable {
    if (!projectDActive) revert NotActive();

    if (projectDCounter == PROJECT_D_LIMIT) revert OutOfSupply();

    if (msg.value < projectDPrice) revert IncorrectPayment();

    if (msg.sender != ERC721A.ownerOf(tokenId)) revert OnlyTokenOwner();

    if (projectDId[tokenId] > 0) revert AlreadyClaimed();

    // Pick a random allocation using Fisher-Yates shuffle
    uint256 boundary = PROJECT_D_LIMIT - projectDCounter++;
    uint256 rand = getRandomNumber(boundary);

    projectDId[tokenId] = (projectDRandoms[rand] == 0) ? rand : projectDRandoms[rand];

    projectDRandoms[rand] = projectDRandoms[boundary] == 0 ? boundary : projectDRandoms[boundary];
  }

  // Owner Methods *****************************************************

  function setBaseURI(string calldata newUri) external onlyOwner {
    baseURI = newUri;
  }

  function setMintSigner(address newSigner) external onlyOwner {
    mintSigner = newSigner;
  }

  function setRoyalties(address recipient, uint96 value) external onlyOwner {
    if (recipient == address(0)) revert InvalidAddress();

    _setDefaultRoyalty(recipient, value);
  }

  function setMintActive(bool active) external onlyOwner {
    mintActive = active;
  }

  function setProjectDBaseURI(string calldata newUri) external onlyOwner {
    projectDBaseURI = newUri;
  }

  function setProjectDActive(bool active) external onlyOwner {
    projectDActive = active;
  }

  function setProjectDPrice(uint256 price) external onlyOwner {
    projectDPrice = price;
  }

  function setTether(address tetherAddress) external onlyOwner {
    uint32 size;
    assembly {
      size := extcodesize(tetherAddress)
    }
    if (size == 0) revert InvalidAddress();

    Tether = ITether(tetherAddress);

    try Tether.supportsInterface(type(ITether).interfaceId) returns (bool supported) {
      if (!supported) revert InvalidAddress();
    } catch {
      revert InvalidAddress();
    }
  }

  function withdraw() external onlyOwner {
    if (address(this).balance == 0) revert ZeroBalance();

    for (uint256 i = 0; i < _payees.length; i++) {
      release(payable(payee(i)));
    }
  }

  // Private Methods *****************************************************

  function validateSignature(bytes memory signature) private view {
    if (mintSigner == address(0)) revert SignerNotSet();

    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(TYPEHASH, msg.sender))));

    address signer = digest.recover(signature);

    if (signer != mintSigner) revert InvalidSignature();
  }

  /// @dev Returns a pseudo random number between 1 and max
  function getRandomNumber(uint256 max) private view returns (uint256) {
    uint256 number = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase, block.timestamp, max)));

    return (number % max) + 1;
  }

  function _onlyEOA(address account) internal view {
    if (account != tx.origin || account.code.length > 0) {
      revert OnlyEOA();
    }
  }

  function _sufficientSupply(uint256 amount) internal view {
    if ((totalSupply() + amount) > SUPPLY_LIMIT) {
      revert OutOfSupply();
    }
  }

  function _firstTimeMint(address account) internal view {
    if (_numberMinted(account) > 0) {
      revert MintLimitExceeded();
    }
  }

  // Override Methods *****************************************************

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    // return projectD tokenURI if applicable
    if (projectDId[tokenId] > 0) {
      string memory _projectDBaseURI = projectDBaseURI;
      if (bytes(_projectDBaseURI).length != 0) {
        return string(abi.encodePacked(_projectDBaseURI, projectDId[tokenId].toString()));
      }
    }

    return super.tokenURI(tokenId);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {
    super._afterTokenTransfers(from, to, startTokenId, quantity);

    if (address(Tether) != address(0)) {
      unchecked {
        uint256 updatedIndex = startTokenId;
        uint256 end = updatedIndex + quantity;
        do {
          Tether.tether(updatedIndex++);
        } while (updatedIndex < end);
      }
    }
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721A) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}