pragma solidity ^0.8.8;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./lib/ERC721.sol";
import "./lib/Hybrid.sol";
import "./lib/AccessControl.sol";

contract OneOfNoneHybrid is ERC721, Hybrid, AccessControl, Pausable {
  using Strings for uint256;

  string constant METADATA_FROZEN = "006001";
  string constant LIMIT_REACHED = "006002";

  mapping(uint256 => string) private _freezeMetadata;
  string private _baseURI;

  uint256 public constant LIMIT = 1;

  constructor() {
    _setAdmin(msg.sender);
  }

  /// @notice according to ERC721Metadata
  function name() public pure returns (string memory) {
    return "Lying with Death";
  }

  /// @notice according to ERC721Metadata
  function symbol() public pure returns (string memory) {
    return "1XMS2";
  }

  /// @notice allow minter to retrieve a token
  function mint(address to, TokenStatus status) external virtual whenNotPaused onlyRole(MINTER_ROLE) {
    require(_maxTokenId + 1 <= LIMIT, LIMIT_REACHED);

    uint256 tokenId = _maxTokenId + 1;

    _mint(to, tokenId);
    _setStatus(tokenId, status);
  }

  /// @notice Retrieve metadata URI according to ERC721Metadata standard
  /// @dev there is an opportunity to freeze metadata URI
  ///   essentially it means that for the selected tokens we can move metadata to ipfs
  ///   and keep it there forever
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId), NOT_VALID_NFT);

    if (bytes(_freezeMetadata[tokenId]).length > 0) {
      return _freezeMetadata[tokenId];
    }

    return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : '';
  }

  /// @notice Only owner of the token can freeze metadata.
  /// @dev this operation is irreversible, use with caution
  function freezeMetadataURI(uint256 tokenId, string calldata uri) external onlyAdmin {
    require(_exists(tokenId), NOT_VALID_NFT);
    require(bytes(_freezeMetadata[tokenId]).length == 0, METADATA_FROZEN);

    _freezeMetadata[tokenId] = uri;
  }

  /// @notice change base URI for the metadata
  function setMetadataBaseURI(string calldata uri) external onlyAdmin {
    _baseURI = uri;
  }

  /// @notice pause contract
  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /// @notice unpause
  function unpause() public onlyAdmin {
    _unpause();
  }

  /// MARK: Hybrid
  function setStatus(uint256 tokenId, TokenStatus status) public onlyRole(STATUS_CHANGER_ROLE) {
    require(_exists(tokenId), NOT_VALID_NFT);
    _setStatus(tokenId, status);
  }

  /// @notice beforeTransfer hook
  /// Disallow transfer if token is redeemed
  function _beforeTransfer(address from, address to, uint256 tokenId)
    internal override whenNotPaused notStatus(tokenId, TokenStatus.Redeemed) {}

  /// MARK: AccessControl implementation
  function setRole(address to, bytes32 role) public onlyAdmin {
    _grantRole(to, role);
  }

  function revokeRole(address to, bytes32 role) public onlyAdmin {
    _revokeRole(to, role);
  }

  function transferAdmin(address to) public onlyAdmin {
    _setAdmin(to);
  }
}