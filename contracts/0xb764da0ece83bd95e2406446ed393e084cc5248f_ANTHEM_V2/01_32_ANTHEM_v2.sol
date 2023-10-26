// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./ANTHEMNestingView.sol";

contract ANTHEM_V2 is
  Initializable,
  ERC721Upgradeable,
  OwnableUpgradeable,
  ERC2981Upgradeable,
  DefaultOperatorFiltererUpgradeable,
  UUPSUpgradeable
{
  string private baseURI;

  uint256 public totalSupply;

  mapping(address => bool) public admins;

  function initialize() public initializer {
    __ERC721_init("ANTHEM", "ANTHEM");
    __ERC2981_init();
    admins[msg.sender] = true;
    totalSupply = 6000;
    nestingTransfer = 1;

    __Ownable_init();
    __UUPSUpgradeable_init();
    __DefaultOperatorFilterer_init();

    _setDefaultRoyalty(msg.sender, 750);
  }

  function setAdmin(address _admin, bool isAdmin) public onlyOwner {
    admins[_admin] = isAdmin;
  }

  function airdrop(
    uint256[] calldata _tokenIds,
    address[] calldata _airdropAddresses
  ) external onlyOwner {
    require(_tokenIds.length == _airdropAddresses.length, "array length unmatch");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _safeMint(_airdropAddresses[i], _tokenIds[i]);
    }
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   * @dev do withdraw eth.
   */
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(os, "withdraw error");
  }

  /**
   * @dev Interface
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721Upgradeable, ERC2981Upgradeable) returns (bool) {
    return
      ERC721Upgradeable.supportsInterface(interfaceId) ||
      ERC2981Upgradeable.supportsInterface(interfaceId);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  // operator-filter-registry

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /**
    @dev tokenId to nesting start time (0 = not nesting).
     */
  mapping(uint256 => uint256) public nestingStarted;

  function getNestingStarted(uint256 tokenId) external view returns (uint256) {
    return nestingStarted[tokenId];
  }

  /**
    @dev MUST only be modified by safeTransferWhileNesting(); if set to 2 then
    the _beforeTokenTransfer() block while nesting is disabled.
     */
  uint256 private nestingTransfer;

  /**
    @notice Transfer a token between addresses while the ANTHEM is minting,
    thus not resetting the nesting period.
     */
  function safeTransferWhileNesting(address from, address to, uint256 tokenId) external {
    require(ownerOf(tokenId) == _msgSender(), "ANTHEM: Only owner");
    nestingTransfer = 2;
    safeTransferFrom(from, to, tokenId);
    nestingTransfer = 1;
  }

  /**
    @dev Block transfers while nesting.
     */
  function _beforeTokenTransfer(
    address from,
    address,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal view override {
    uint256 tokenId = firstTokenId;
    for (uint256 end = tokenId + batchSize; tokenId < end; ++tokenId) {
      require(
        nestingStarted[tokenId] == 0 || nestingTransfer == 2 || from == address(0),
        "ANTHEM: nesting"
      );
    }
  }

  /**
    @dev Emitted when a ANTHEM begins nesting.
     */
  event Nested(uint256 indexed tokenId);

  /**
    @dev Emitted when a ANTHEM stops nesting; either through standard means or
    by expulsion.
     */
  event Unnested(uint256 indexed tokenId);

  /**
    @notice Changes the ANTHEM's nesting status.
    */
  function toggleNesting(uint256 tokenId) internal virtual {
    require(
      ownerOf(tokenId) == _msgSender() || getApproved(tokenId) == _msgSender(),
      "Not approved nor owner"
    );

    uint256 start = nestingStarted[tokenId];
    if (start == 0) {
      nestingStarted[tokenId] = block.timestamp;
      emit Nested(tokenId);
    } else {
      // nestingTotal[tokenId] += block.timestamp - start;
      nestingStarted[tokenId] = 0;
      emit Unnested(tokenId);
    }
  }

  /**
    @notice Changes the ANTHEMs' nesting statuss (what's the plural of status?
    statii? statuses? status? The plural of sheep is sheep; maybe it's also the
    plural of status).
    @dev Changes the ANTHEMs' nesting sheep (see @notice).
     */
  function toggleNesting(uint256[] calldata tokenIds) external virtual {
    uint256 n = tokenIds.length;
    for (uint256 i = 0; i < n; ++i) {
      toggleNesting(tokenIds[i]);
    }
  }

  /**
    @notice Admin-only ability to expel a ANTHEM from the nest.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has nested and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting bird to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because nesting would then be all-or-nothing for all of a particular owner's
    ANTHEMs.
     */

  function expelFromNest(uint256[] calldata tokenIds) external virtual {
    uint256 n = tokenIds.length;
    for (uint256 i = 0; i < n; ++i) {
      expelFromNest(tokenIds[i]);
    }
  }

  function expelFromNest(uint256 tokenId) public virtual {
    require(admins[msg.sender], "Only admins can call this function");
    require(nestingStarted[tokenId] != 0, "ANTHEM: not nested");
    nestingStarted[tokenId] = 0;
    emit Unnested(tokenId);
  }

  /**
   * @dev Initializes the past staking information for inheritance.
   * @param tokenIds An array of token IDs representing the past staked tokens.
   * @param timestamps An array of timestamps representing the past staking start times.
   */
  function initializeNesting(
    uint256[] calldata tokenIds,
    uint256[] calldata timestamps
  ) external onlyOwner {
    require(tokenIds.length == timestamps.length, "array length no match.");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      nestingStarted[tokenIds[i]] = timestamps[i];
      emit Nested(tokenIds[i]);
    }
  }
}