// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IMetaStreetApesNFT.sol";

contract MetaStreetApesNFT is ERC721Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, IMetaStreetApesNFT {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNING_ROLE = keccak256("BURNING_ROLE");

  uint256 public mintId;

  string public uri;

  event SetURI(string _uri);
  event SetLockTransfer(uint256 _startLock, uint256 _endLock);
  event SetMaxMintId(uint256 _maxMintId);
  event Mint(address indexed _to, uint256 _mintId);
  event BulkMint(address indexed _to, uint256 _numberOfNft);

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return _interfaceId == type(IMetaStreetApesNFT).interfaceId || super.supportsInterface(_interfaceId);
  }

  /**
   * @dev Upgradable initializer
   * @param _name Token name
   * @param _symbol Token symbol
   * @param _uri URI string
   */
  function __MetaStreetApesNFT_init(
    string memory _name,
    string memory _symbol,
    string memory _uri
  ) external initializer {
    __Ownable_init();
    __AccessControl_init();
    __ERC721_init(_name, _symbol);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    uri = _uri;
    mintId = 1;
  }

  /**
   * @dev Return of base uri
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  /**
   * @dev See {IERC721-_safeTransfer}. control transfer function logic
   * @dev Error Details
   * - 0x1: Transfer is not allowed
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual override {
    super._safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @notice Update URI
   * @dev Only callable by owner
   * @param _uri URI for metadata
   */
  function setURI(string memory _uri) external onlyOwner {
    uri = _uri;

    emit SetURI(_uri);
  }

  /**
   * @notice Mint a new token Id
   * @dev Only callable by MINTER ROLE
   * @param _to Address where id need to be minted
   * @dev Error Details
   * - 0x1: User can't mint more than mint id
   */
  function mint(address _to) external override onlyRole(MINTER_ROLE) returns (uint256) {
    super._mint(_to, mintId);
    mintId++;

    emit Mint(_to, mintId - 1);
    return mintId - 1;
  }

  /**
   * @notice Mint a new tokens according to Number of NFT
   * @dev Only callable by MINTER ROLE
   * @param _to Address where ids need to be minted
   * @param _numberOfNft Total number of NFTs to be minted
   * @dev Error Details
   * - 0x1: User can't mint more than mint id
   */
  function bulkMint(uint256 _numberOfNft, address _to) external override onlyRole(MINTER_ROLE) {
    for (uint256 id = mintId; id < mintId + _numberOfNft; id++) {
      super._mint(_to, id);
    }
    mintId = mintId + _numberOfNft;

    emit BulkMint(_to, _numberOfNft);
  }

  /**
   * @notice Burn an NFT
   * @dev Burn an NFT
   * @param _id Token id
   */
  function burn(uint256 _id) external onlyRole(BURNING_ROLE) {
    _burn(_id);
  }

  /**
   * @notice Burn NFTs
   * @dev Burn NFTs
   * @param _ids Token id
   */
  function bulkBurn(uint256[] memory _ids) external onlyRole(BURNING_ROLE) {
    for (uint256 i; i < _ids.length; i++)
      _burn(_ids[i]);
  }

}