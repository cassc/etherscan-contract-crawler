// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../libraries/interfaces/IRedlionGazette.sol';

/**
 * @title Redlion Gazettes
 * @author Gui "Qruz" Rodrigues (@0xqruz)
 * @dev Redlion Gazette is an ERC721 non-fungible token (NFT) contract that allows the creation and distribution of NFTs that represent gazettes.
 * @notice This contract is made for Redlion (https://redlion.red)
 */
contract RedlionGazette is
  Initializable,
  IRedlionGazette,
  ERC721Upgradeable,
  AccessControlUpgradeable
{
  /*///////////////////////////////////////////////////////////////
                         VARIABLES
  ///////////////////////////////////////////////////////////////*/

  address CURRENT_MANAGER;
  bytes32 public MANAGER_ROLE;
  bytes32 public OWNER_ROLE;

  uint256 CURRENT_ISSUE;

  uint256[] ISSUE_IDS;

  mapping(uint256 => Issue) public ISSUES;
  mapping(uint256 => uint256) public TOKEN_TO_ISSUE;

  uint256 public MAX_MINT_TX;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev Initializes the contract with a given manager address.
   * @param _manager The address of the contract manager.
   */
  function initialize(address _manager) public initializer {
    MANAGER_ROLE = keccak256('MANAGER');
    OWNER_ROLE = keccak256('OWNER');
    MAX_MINT_TX = 5;
    __ERC721_init('Redlion Gazette', 'RLGAZETTE');
    __AccessControl_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(OWNER_ROLE, msg.sender);
    _setManager(_manager);
  }

  /*///////////////////////////////////////////////////////////////
                         lAUNCHING/MINTING
  ///////////////////////////////////////////////////////////////*/

  /**
   * @dev Launches a new issue of the publication.
   * @param _issue The number of the new issue being launched.
   * @param _saleSize The number of tokens available for sale for this issue.
   *                   Set to 0 if the issue is an open edition.
   * @param _uri A URI where more information about the issue can be found.
   * @custom:throws INVALID_ISSUE_NUMBER if the issue number is lower than the current issue number.
   * @custom:throws ISSUE_ALREADY_EXISTS if an issue with the same number has already been launched.
   */
  function launchIssue(
    uint256 _issue,
    uint256 _saleSize,
    string memory _uri
  ) external override(IRedlionGazette) onlyRole(MANAGER_ROLE) {
    require(CURRENT_ISSUE < _issue, 'INVALID_ISSUE_NUMBER');
    require(ISSUES[_issue].timestamp == 0, 'ISSUE ALREADY EXISTS');
    CURRENT_ISSUE = _issue;
    ISSUES[_issue].timestamp = block.timestamp;
    if (_saleSize == 0) ISSUES[_issue].openEdition = true;
    else ISSUES[_issue].saleSize = _saleSize;
    ISSUES[_issue].uri = _uri;
    ISSUES[_issue].issue = _issue;
    ISSUE_IDS.push(CURRENT_ISSUE);

    emit IssueLaunched(_issue, _saleSize);
  }

  /**
   * @dev Mints new tokens for a specific issue of the publication.
   * @param _to The address the minted tokens should be sent to.
   * @param _issue The number of the issue the tokens belong to.
   * @param _amount The number of tokens to mint.
   * @param claim Whether the tokens being minted are being claimed.
   *              Set to false if the tokens are being sold.
   * @return An array of the token IDs of the minted tokens.
   * @custom:throws EXCEEDING_AMOUNT if the number of tokens being minted in a single transaction exceeds the MAX_MINT_TX limit.
   * @custom:throws EXCEEDING_MINTING_AMOUNT if the number of tokens being minted exceeds the number available for sale in an open edition.
   */
  function mint(
    address _to,
    uint256 _issue,
    uint256 _amount,
    bool claim
  )
    external
    override(IRedlionGazette)
    onlyRole(MANAGER_ROLE)
    returns (uint256[] memory)
  {
    require(_amount <= MAX_MINT_TX, 'EXCEEDING_AMOUNT');
    _requireIssueLaunched(_issue);
    
    if (!claim && !ISSUES[_issue].openEdition) {
      if (_amount <= ISSUES[_issue].saleSize) {
        ISSUES[_issue].saleSize -= _amount;
      } else revert('EXCEEDING_MINTING_AMOUNT');
    }

    uint256[] memory tokenIds = new uint256[](_amount);
    for (uint256 i = 0; i < _amount; i++) {
      uint256 tokenId = (_issue * (10 ** 6)) + (ISSUES[_issue].totalSupply++);
      TOKEN_TO_ISSUE[tokenId] = _issue;
      tokenIds[i] = tokenId;
      _mint(_to, tokenId);
      emit IRedlionGazette.MintedIssue(_to, _issue, tokenId);
    }

    return tokenIds;
  }

  /*///////////////////////////////////////////////////////////////
                             UTILITY
  ///////////////////////////////////////////////////////////////*/

  /**
   * @dev Returns a list of available issues of the publication.
   * @return An array of the numbers of the available issues.
   */
  function issueList() public view returns (uint256[] memory) {
    return ISSUE_IDS;
  }

  /**
   * @dev Returns the number of an issue a specific token belongs to.
   * @param _tokenId The ID of the token to check.
   * @return The number of the issue the token belongs to.
   * @custom:throws INVALID_TOKEN if the token ID is invalid.
   */
  function tokenToIssue(
    uint256 _tokenId
  ) public view override returns (uint256) {
    _requireMinted(_tokenId);

    return TOKEN_TO_ISSUE[_tokenId];
  }

  /**
   * @dev Returns whether a specific issue has been launched.
   * @param _issue The number of the issue to check.
   * @return true if the issue has been launched, false otherwise.
   */
  function isIssueLaunched(
    uint256 _issue
  ) public view override(IRedlionGazette) returns (bool) {
    return ISSUES[_issue].timestamp != 0;
  }

  /**
   * @dev Sets the URI for a specific issue.
   * @param _issue The number of the issue to set the URI for.
   * @param _uri The URI to set for the issue.
   * @custom:throws ISSUE_NOT_LAUNCHED if the issue has not been launched.
   * @custom:throws AccessError if the caller does not have the MANAGER_ROLE.
   */
  function setIssueURI(
    uint256 _issue,
    string memory _uri
  ) external onlyRole(OWNER_ROLE) {
    _requireIssueLaunched(_issue);

    ISSUES[_issue].uri = _uri;
  }

  /**
   * @dev Sets the maximum number of tokens that can be minted in a single transaction.
   * @param _max The new maximum number of tokens that can be minted in a single transaction.
   * @custom:throws AccessError if the caller is not the contract owner.
   */
  function setMaxMintTx(uint256 _max) external onlyRole(OWNER_ROLE) {
    MAX_MINT_TX = _max;
  }

  /**
   * @dev Returns the URI for a specific token.
   * @param _tokenId The ID of the token to retrieve the URI for.
   * @return The URI for the token.
   * @custom:throws ERC721 error if the token ID is invalid.
   */
  function tokenURI(
    uint256 _tokenId
  ) public view override(ERC721Upgradeable) returns (string memory) {
    _requireMinted(_tokenId);
    return ISSUES[TOKEN_TO_ISSUE[_tokenId]].uri;
  }

  /**
   * @dev Returns the issue of the publication that was launched at a specific time.
   * @param _timestamp The timestamp to check for the issue launched.
   * @return A struct containing the details of the issue launched at the given timestamp.
   * @custom:throws ISSUE_NOT_LAUNCHED if no issue was launched at the given timestamp.
   */
  function timeToIssue(
    uint256 _timestamp
  ) public view override(IRedlionGazette) returns (Issue memory) {
    Issue memory _issue;

    if (ISSUES[CURRENT_ISSUE].timestamp <= _timestamp)
      _issue = ISSUES[CURRENT_ISSUE];
    else {
      for (uint256 i = 0; i < issueList().length; i++) {
        if (
          ISSUES[ISSUE_IDS[i]].timestamp <= _timestamp &&
          ISSUES[ISSUE_IDS[i]].timestamp > _issue.timestamp
        ) _issue = ISSUES[i];
      }
    }

    return _issue;
  }

  /*///////////////////////////////////////////////////////////////
                          OWNER FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Withdraws the contract balance
   * @dev Only the owner can withdraw the contract balance
   */
  function withdraw() public onlyRole(OWNER_ROLE) {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /**
   * @dev Sets the contract manager.
   * @param _manager The address of the new contract manager.
   * @custom:throws AccessError if the caller does not have the OWNER_ROLE.
   */
  function setManager(address _manager) external onlyRole(OWNER_ROLE) {
    _setManager(_manager);
  }

  /*///////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  function _setManager(address _manager) internal {
    if (CURRENT_MANAGER != address(0)) {
      _revokeRole(MANAGER_ROLE, CURRENT_MANAGER);
    }
    _grantRole(MANAGER_ROLE, _manager);
    CURRENT_MANAGER = _manager;
  }

  function _requireIssueLaunched(uint256 _issue) internal view {
    require(isIssueLaunched(_issue), 'ISSUE_NOT_LAUNCHED');
  }

  // The following functions are overrides required by Solidity.

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
}