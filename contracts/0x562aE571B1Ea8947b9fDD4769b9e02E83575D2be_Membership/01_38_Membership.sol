/**
 *  /##    /##                              /##           /##                     /##
 * | ##   | ##                             | ##          | ##                    | ##
 * | ##   | ## /######  /##   /##  /###### | ##  /###### | ## /##   /##  /###### | #######
 * |  ## / ##//##__  ##|  ## /##/ /##__  ##| ## /##__  ##| ##| ##  | ## /##__  ##| ##__  ##
 *  \  ## ##/| ##  \ ## \  ####/ | ########| ##| ##  \ ##| ##| ##  | ##| ##  \ ##| ##  \ ##
 *   \  ###/ | ##  | ##  >##  ## | ##_____/| ##| ##  | ##| ##| ##  | ##| ##  | ##| ##  | ##
 *    \  #/  |  ######/ /##/\  ##|  #######| ##|  #######| ##|  #######| #######/| ##  | ##
 *     \_/    \______/ |__/  \__/ \_______/|__/ \____  ##|__/ \____  ##| ##____/ |__/  |__/
 *                                              /##  \ ##     /##  | ##| ##
 *                                             |  ######/    |  ######/| ##
 *                                              \______/      \______/ |__/
 *
 *                                             by Larva Labs (Matt Hall and John Watkinson)
 *                                                 in partnership with the Fingerprints DAO
 *
 * To get the complete Voxelglyph script, simply call function voxelglyphScriptJava and decode from base64.
 * To get the co-ordinates for the Voxelglyph structure, save the returned Java script and run with a Java runtime environment.
 *
 * This ERC721 smart contract is used as the governance contract for Fingerprints DAO.
 * It was developed by arod.studio in partnership with Fingerprints DAO.
 */

/**
 * @title Voxelglyphs NFT contract - The Fingerprints' Membership NFTs by Larva Labs
 * @author arod.studio and Fingerprints DAO
 * This contract is used to manage ERC721 Membership tokens from Fingerprints DAO.
 * Larva Labs created the Voxelglyph art used as the image in this NFT.
 *
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract Membership is
  ERC721,
  ERC721Enumerable,
  ERC721Royalty,
  Pausable,
  AccessControl,
  ERC721Burnable,
  EIP712,
  ERC721Votes,
  DefaultOperatorFilterer
{
  error MaxSupplyExceeded();
  event BaseURIChanged(string newBaseURI);
  event DefaultRoyaltySet(address payoutAddress, uint96 royaltyFee);

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  /// @notice The base URI for all token IDs.
  /// @dev The base URI is stored in a public state variable.
  string public baseURIValue;

  /// @notice The Voxelglyph java script in base64.
  string public voxelglyphScriptJava;

  /// @notice The role identifier for users who are allowed to mint tokens.
  /// @dev The role identifier is created by hashing the string 'MINTER_ROLE'.
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  /// @notice The maximum supply of tokens that can be minted.
  /// @dev The maximum supply is set to 2000 and cannot be changed after deployment.
  uint16 public constant MAX_SUPPLY = 2000;

  constructor(
    string memory _baseURIValue,
    address _adminAddress,
    address _payoutAddress,
    uint96 _royaltyFee,
    string memory _voxelglyphJavaScript
  ) ERC721('Voxelglyph', '#') EIP712('Voxelglyph', '1') {
    _grantRole(DEFAULT_ADMIN_ROLE, _adminAddress);
    _grantRole(MINTER_ROLE, _adminAddress);
    _setDefaultRoyalty(_payoutAddress, _royaltyFee);
    baseURIValue = _baseURIValue;
    voxelglyphScriptJava = _voxelglyphJavaScript;
  }

  /// @notice Pauses all token transfers.
  /// @dev Only users with the 'DEFAULT_ADMIN_ROLE' are allowed to call this function.
  function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /// @notice Unpauses all token transfers.
  /// @dev Only users with the 'DEFAULT_ADMIN_ROLE' are allowed to call this function.
  function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  /// @notice Mints new tokens and assigns them to the specified address.
  /// @dev Only users with the 'MINTER_ROLE' are allowed to call this function.
  /// @param _to The address of the future owner of the token.
  /// @param _amount The amount of tokens to mint.
  function safeMint(
    address _to,
    uint16 _amount
  ) external onlyRole(MINTER_ROLE) {
    uint256 tokenId = _tokenIdCounter.current();
    if (tokenId + _amount > MAX_SUPPLY) {
      revert MaxSupplyExceeded();
    }

    for (uint16 i = 0; i < _amount; i++) {
      _tokenIdCounter.increment();
      uint256 mintedTokenId = _tokenIdCounter.current();
      _safeMint(_to, mintedTokenId);
    }
  }

  /// @notice Sets the default royalty for the contract.
  /// @dev Only users with the 'DEFAULT_ADMIN_ROLE' are allowed to call this function.
  /// @param _payoutAddress The address of the royalty receiver.
  /// @param _royaltyFee The royalty amount.
  function setDefaultRoyalty(
    address _payoutAddress,
    uint96 _royaltyFee
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setDefaultRoyalty(_payoutAddress, _royaltyFee);
    emit DefaultRoyaltySet(_payoutAddress, _royaltyFee);
  }

  /// @notice Returns the base URI for all token IDs.
  function _baseURI() internal view override returns (string memory) {
    return baseURIValue;
  }

  /// @notice Sets the base URI for the contract.
  /// @dev Only users with the 'DEFAULT_ADMIN_ROLE' are allowed to call this function.
  /// @param _newBaseURI The new base URI.
  function setBaseURI(
    string memory _newBaseURI
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    baseURIValue = _newBaseURI;
    emit BaseURIChanged(_newBaseURI);
  }

  /// @notice Returns the URI for a given token ID.
  /// @dev The token ID must exist, otherwise this function will revert.
  /// @param _tokenId The ID of the token to retrieve the URI for.
  function tokenURI(
    uint256 _tokenId
  ) public view override returns (string memory) {
    _requireMinted(_tokenId);

    string memory baseURI = _baseURI();

    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId)))
        : '';
  }

  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _batchSize
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _batchSize
  ) internal override(ERC721, ERC721Votes) {
    super._afterTokenTransfer(_from, _to, _tokenId, _batchSize);
  }

  function _burn(uint256 _tokenId) internal override(ERC721, ERC721Royalty) {
    super._burn(_tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC721, AccessControl, ERC721Royalty, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /// @notice Allows or disallows an operator to manage all of the caller's tokens.
  /// @dev Overrides the equivalent function in the ERC721 standard to include a check for allowed operators.
  /// @param _operator The operator to change the approval status for.
  /// @param _approved The new approval status for the operator.
  function setApprovalForAll(
    address _operator,
    bool _approved
  ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(_operator) {
    super.setApprovalForAll(_operator, _approved);
  }

  /// @notice Approves an operator to manage a specific token.
  /// @dev Overrides the equivalent function in the ERC721 standard to include a check for allowed operators.
  /// @param _operator The operator to approve.
  /// @param _tokenId The ID of the token to approve the operator for.
  function approve(
    address _operator,
    uint256 _tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(_operator) {
    super.approve(_operator, _tokenId);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(_from) {
    super.transferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(_from) {
    super.safeTransferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  ) public override(ERC721, IERC721) onlyAllowedOperator(_from) {
    super.safeTransferFrom(_from, _to, _tokenId, _data);
  }
}