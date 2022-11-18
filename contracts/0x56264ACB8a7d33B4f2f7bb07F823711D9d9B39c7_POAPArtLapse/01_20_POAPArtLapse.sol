// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract POAPArtLapse is Initializable,
  ContextUpgradeable,
  ERC721BurnableUpgradeable,
  ERC721PausableUpgradeable,
  ERC721URIStorageUpgradeable,
  AccessControlUpgradeable,
  EIP712Upgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;

  /** State that tokenURI is permanent. */
  event PermanentURI(string _value, uint256 indexed _id);

  /** Emitted after a new token is created. */
  event LapseMinted(string mintId, uint256 tokenId);

  /** Last token id minted, increment before new token. */
  CountersUpgradeable.Counter private _tokenIds;

  /** Permission roles. */
  bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

  /** Stored lapse canvas id by token id. */
  mapping(uint256 => string) public tokenCanvasId;

  /** Keep record of minted by mint id. */
  mapping(string => bool) public minted;

  /** Which address will receive the fee when minting. */
  address payable public feeReceiver;

  /** How much minting value is required.
   *  Not used anymore, now the fee value is part of the signature. */
  uint256 public feeValue;

  function initialize(
    string memory _name,
    string memory _symbol,
    address payable _feeReceiver
  ) public initializer {
    __POAPArtLapses_init(_name, _symbol, _feeReceiver);
  }

  function __POAPArtLapses_init(
    string memory _name,
    string memory _symbol,
    address payable _feeReceiver
  ) internal initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721_init_unchained(_name, _symbol);
    __ERC721Burnable_init_unchained();
    __ERC721Pausable_init_unchained();
    __ERC721URIStorage_init_unchained();
    __AccessControl_init_unchained();
    __AccessControl_init_unchained();
    __EIP712_init_unchained("POAPArtLapse", "1");
    __POAPArtNFT_init_unchained(_feeReceiver);
  }

  function __POAPArtNFT_init_unchained(
    address payable _feeReceiver
  ) internal initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    feeReceiver = _feeReceiver;
  }

  /** Mint a new signed lapse into a token id. Given signature must be signed
   *  by an address with signer role. */
  function mint(
    string calldata canvasId,
    string calldata mintId,
    uint256 expire,
    string calldata metadataUrl,
    bytes calldata signature
  ) public payable returns (uint256) {
    require(minted[mintId] == false, "already minted");
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp < expire, "lapse expired");

    /** Make sure signature is valid and get the address of the signer. */
    address signer = _signerLapse(canvasId, mintId, expire, metadataUrl, signature);

    /** The signer must be is authorized to mint by signer role. */
    require(hasRole(SIGNER_ROLE, signer), "only signer");

    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();

    minted[mintId] = true;
    feeReceiver.transfer(msg.value);
    emit LapseMinted(mintId, newTokenId);

    _mint(_msgSender(), newTokenId);
    _setTokenURI(newTokenId, metadataUrl);
    tokenCanvasId[newTokenId] = canvasId;

    return newTokenId;
  }

  /** Verifies the signature for a given Lapse. */
  function _signerLapse(
    string memory canvasId,
    string memory mintId,
    uint256 expire,
    string memory metadataUrl,
    bytes memory signature
  ) internal view returns (address) {
    bytes32 digest = _hashLapse(canvasId, mintId, expire, metadataUrl);
    return ECDSAUpgradeable.recover(digest, signature);
  }

  /** Returns a hash of the given Lapse, prepared using EIP712 typed data
   *  hashing rules. */
  function _hashLapse(
    string memory canvasId,
    string memory mintId,
    uint256 expire,
    string memory metadataUrl
  ) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256(bytes("Lapse(string canvasId,string mintId,uint256 expire,string metadataUrl,uint256 feeValue,address owner)")),
      keccak256(bytes(canvasId)),
      keccak256(bytes(mintId)),
      expire,
      keccak256(bytes(metadataUrl)),
      msg.value,
      _msgSender()
    )));
  }

  function pause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function setFeeReceiver(address payable newFeeReceiver) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    feeReceiver = newFeeReceiver;
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIds.current();
  }

  function tokenURI(uint256 tokenId) public view virtual
    override (ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual
    override (AccessControlUpgradeable, ERC721Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual
    override (ERC721Upgradeable, ERC721PausableUpgradeable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal virtual
    override (ERC721Upgradeable, ERC721URIStorageUpgradeable)
  {
    super._burn(tokenId);
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual
    override (ERC721URIStorageUpgradeable)
  {
    super._setTokenURI(tokenId, _tokenURI);

    /** Freeze token url as OpenSea metadata standards. */
    emit PermanentURI(_tokenURI, tokenId);
  }
}