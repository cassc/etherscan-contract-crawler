// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract MintPass is
  ERC1155Upgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  AccessControlEnumerableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using ECDSAUpgradeable for bytes32;
  address internal signer;
  uint256 public constant PRICE = 1000000000000000000;
  uint256 public constant MINT_PASS_ID = 0;
  uint256 public constant TOTAL_SUPPLY = 5000;
  mapping(bytes => bool) internal signatureUsed;
  address internal gucciContractAddress;
  address internal payoutAddress;
  string private _baseMetadataURI;

  using CountersUpgradeable for CountersUpgradeable.Counter;
  using StringsUpgradeable for uint256;

  CountersUpgradeable.Counter internal minted;

  uint256 private mintStartTime;
  uint256 private mintEndTime;

  function initialize(string memory _baseURI) external initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    __AccessControlEnumerable_init();
    __ERC1155_init(_baseURI);

    _baseMetadataURI = _baseURI;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function version() external pure virtual returns (string memory) {
    return "1.0.1";
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable)
  returns (bool)
  {
    return
      interfaceId == type(IERC1155Upgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function uri(uint256 _id)
  public
  view
  override
  returns (string memory)
  {
    return string(abi.encodePacked(_baseMetadataURI, _id.toString()));
  }

  function getSignatureUsed(bytes calldata signature)
  public
  view
  returns (bool)
  {
    return signatureUsed[signature];
  }

  function getMinted()
  public
  view
  returns (uint256)
  {
    return minted.current();
  }


  function setSigner(address _signer)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    signer = _signer;
  }

  function getSigner()
  external
  view
  returns (address)
  {
    return signer;
  }

  function setPayoutAddress(address _payoutAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    payoutAddress = _payoutAddress;
  }

  function getPayoutAddress()
  external
  view
  returns (address)
  {
    return payoutAddress;
  }

  function setGucciContractAddress(address contractAddress)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    gucciContractAddress = contractAddress;
  }

  function getGucciContractAddress()
  external
  view
  returns (address)
  {
    return gucciContractAddress;
  }

  function _getSignatureSigner(bytes32 hash, bytes memory signature)
  internal
  pure
  returns (address)
  {
    return hash.toEthSignedMessageHash().recover(signature);
  }

  function _verifyClaim(
    address account,
    bytes memory signature
  )
  internal
  view
  returns (bool)
  {
    return _getSignatureSigner(keccak256(abi.encodePacked(account)), signature) == signer;
  }

  function _mint(address wallet, bytes memory signature)
  internal
  {
    require(signatureUsed[signature] != true, "Signature already used to mint");
    require(minted.current() < TOTAL_SUPPLY, "All tokens minted already");
    require(block.timestamp >= mintStartTime, "Minting hasn't started yet");
    require(block.timestamp <= mintEndTime, "Minting has ended");

    _mint(wallet, MINT_PASS_ID, 1, "");
    signatureUsed[signature] = true;
    minted.increment();
  }

  function mint(bytes memory signature)
  external
  payable
  nonReentrant
  {
    require(signer != address(0), "Signer not set yet");
    require(_verifyClaim(_msgSender(), signature), "Mismatched signature");
    require(msg.value >= PRICE, "Insufficent eth sent");

    _mint(_msgSender(), signature);

    if (payoutAddress != address(0)) {
      payable(payoutAddress).transfer(PRICE);
    }

    if (msg.value > PRICE) {
      uint256 oversentEth = msg.value - PRICE;
      payable(msg.sender).transfer(oversentEth);
    }
  }

  function _airdrop(address wallet)
  internal
  {
    require(minted.current() < TOTAL_SUPPLY, "All tokens minted already");
    _mint(wallet, MINT_PASS_ID, 1, "");
  }

  function airdropPass(address[] calldata wallets)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    for (uint256 i = 0; i < wallets.length; i++) {
      _airdrop(wallets[i]);
    }
  }

  function burn(address wallet)
  external
  returns (bool)
  {
    require(_msgSender() == gucciContractAddress, "Not allowed to call function");
    require(balanceOf(wallet, MINT_PASS_ID) >= 1, "Minter needs to own mint pass");

    _burn(wallet, MINT_PASS_ID, 1);

    return true;
  }

  function setMintTimes(uint256 _mintStartTime, uint256 _mintEndTime)
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    mintStartTime = _mintStartTime;
    mintEndTime = _mintEndTime;
  }

  function withdraw()
  external
  onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(payoutAddress != address(0), "Payout address not set");
    payable(payoutAddress).transfer(address(this).balance);
  }

  function _authorizeUpgrade(address newImplementation)
  internal
  virtual
  override
  onlyRole(DEFAULT_ADMIN_ROLE)
  {}
}