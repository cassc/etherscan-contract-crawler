// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../libraries/interfaces/IRedlionArtdrops.sol';
import '../libraries/interfaces/IRedlionGazetteManager.sol';

/**
 * @title Redlion Artdrops
 * @author Gui "Qruz" Rodrigues (@0xqruz)
 * @dev Redlion Artdrops is a non-fungible token (NFT) contract that allows the creation and distribution of NFTs that represent artdrops. The contract stores the full URI of the artdrop content, which can be accessed by anyone with the token URI. Only the owners can launch new artdrops and the manager mint new tokens.
 * @notice This contract is made for Redlion (https://redlion.red)
 */
contract RedlionArtdrops is
  Initializable,
  IRedlionArtdrops,
  ERC721Upgradeable,
  AccessControlUpgradeable
{
  /*///////////////////////////////////////////////////////////////
                         VARIABLES
  ///////////////////////////////////////////////////////////////*/

  bytes32 public MANAGER_ROLE;
  bytes32 public OWNER_ROLE;

  address CURRENT_MANAGER;

  mapping(uint256 => string) public artdropURI;


  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address _manager) public initializer {
    MANAGER_ROLE = keccak256('MANAGER');
    OWNER_ROLE = keccak256('OWNER');
    __ERC721_init('Redlion Artdrop', 'RLART');
    __AccessControl_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(OWNER_ROLE, msg.sender);
    _setManager(_manager);
  }

  /*///////////////////////////////////////////////////////////////
                              UTILITY
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns whether a token has been claimed or not
   * @param _tokenId The unique identifier of the token
   *  @return True if the token has been claimed, false otherwise
   */
  function isClaimed(
    uint256 _tokenId
  ) public view override(IRedlionArtdrops) returns (bool) {
    return _exists(_tokenId);
  }

  /**
   * @notice Returns the URI of a token
   * @dev Overrides the ERC721Upgradeable function
   * @param _tokenId The unique identifier of the token
   * @return The URI of the token
  */
  function tokenURI(
    uint256 _tokenId
  ) public view override(ERC721Upgradeable) returns (string memory) {
    require(isClaimed(_tokenId), 'TOKEN_NOT_CLAIMED');
    return issueURI(getManager().getRLG().tokenToIssue(_tokenId));
  }

  /**
   * @notice Returns the URI of an artdrop
   * @param _issue The unique identifier of the artdrop
   * @return The URI of the artdrop
   */
  function issueURI(uint256 _issue) public view returns (string memory) {
    _requireIssueLaunched(_issue);
    return artdropURI[_issue];
  }

  /*///////////////////////////////////////////////////////////////
                      MANAGER FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Mints a new Redlion Artdrops token
   * @dev Only the manager can mint new tokens.
   * @param _to The address of the token owner
   * @param _tokenId The unique identifier of the token being minted
   */
  function mint(
    address _to,
    uint256 _tokenId
  ) external override(IRedlionArtdrops) onlyRole(MANAGER_ROLE) {
    uint256 issue = getManager().getRLG().tokenToIssue(_tokenId);
    _requireIssueLaunched(issue);
    _requireArtdropLaunched(issue);
    require(!isClaimed(_tokenId), 'DROP_ALREADY_CLAIMED');
    require(
      getManager().getRLG().ownerOf(_tokenId) == _to,
      'CLAIMANT_NOT_OWNER'
    );

    _mint(_to, _tokenId);
  }

  /*///////////////////////////////////////////////////////////////
                         OWNER FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the new gazette manager contract
   * @dev Only the owner can set the gazette manager contract
   * @param _manager The new gazette manager contract
   */
  function setManager(address _manager) external onlyRole(OWNER_ROLE) {
    _setManager(_manager);
  }

  /**
   * @notice Launches a new artdrop / Changes the current URI
   * @dev Only the owner can launch a new artdrop
   * @param _issue The unique identifier of the artdrop being launched
   * @param _uri The URI of the artdrop metadata
   */
  function launchArtdrop(
    uint256 _issue,
    string calldata _uri
  ) external onlyRole(OWNER_ROLE) {
    _requireIssueLaunched(_issue);
    artdropURI[_issue] = _uri;
    emit ArtdropLaunched(_issue);
  }

  /**
   * @notice Withdraws the contract balance
   * @dev Only the owner can withdraw the contract balance
   */
  function withdraw() public onlyRole(OWNER_ROLE) {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /*///////////////////////////////////////////////////////////////
                            INTERNALS
  ///////////////////////////////////////////////////////////////*/

  function _setManager(address _manager) internal {
    if (CURRENT_MANAGER != address(0)) {
      _revokeRole(MANAGER_ROLE, CURRENT_MANAGER);
    }
    _grantRole(MANAGER_ROLE, _manager);
    CURRENT_MANAGER = _manager;
  }

  /**
   * @notice Returns the current gazette manager contract
   * @return The address of the current gazette manager contract
   */
  function getManager() internal view returns (IRedlionGazetteManager) {
    return IRedlionGazetteManager(CURRENT_MANAGER);
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(AccessControlUpgradeable, ERC721Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _requireIssueLaunched(uint256 _issue) internal view {
    require(
      getManager().getRLG().isIssueLaunched(_issue),
      'ISSUE_NOT_LAUNCHED'
    );
  }

  function _requireArtdropLaunched(uint256 _issue) internal view {
    require(bytes(artdropURI[_issue]).length > 0, 'ARTDROP_NOT_LAUNCHED');
  }
}