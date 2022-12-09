// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/INFBTokenURIGetter.sol";
import "./interfaces/INFB.sol";

contract NFB is
  INFB,
  Ownable,
  AccessControl,
  ERC721A,
  ERC721AQueryable,
  ERC721ABurnable
{
  struct Series {
    string name;
    string description;
  }

  struct Edition {
    uint256 availableFrom;
    uint256 availableUntil;
  }

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  mapping(uint16 => Series) public override series;
  mapping(uint16 => mapping(uint8 => Edition)) public override editions;
  mapping(uint16 => bool) public isSeriesFrozen;
  mapping(uint16 => mapping(uint8 => INFBTokenURIGetter))
    public tokenURIGetters;

  event SeriesSet(uint16 indexed id, string indexed name, string description);
  event EditionSet(
    uint16 indexed seriesId,
    uint8 indexed editionId,
    uint256 availableFrom,
    uint256 availableUntil
  );
  event SeriesFrozen(uint16 indexed id);
  event TokenURIGetterSet(
    uint16 indexed seriesId,
    uint8 indexed editionId,
    address indexed tokenURIGetter
  );

  modifier seriesIsNotFrozen(uint16 id) {
    require(!isSeriesFrozen[id], "NFB: Series already frozen");
    _;
  }

  constructor(string memory name, string memory symbol) ERC721A(name, symbol) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MANAGER_ROLE, msg.sender);
  }

  function mint(
    address to,
    uint256 amount,
    uint16 seriesId,
    uint8 editionId
  ) external override onlyRole(MINTER_ROLE) returns (uint256 startTokenId) {
    require(
      editions[seriesId][editionId].availableUntil >= block.timestamp,
      "NFB: Series or edition is not available"
    );

    startTokenId = _totalMinted();
    _safeMint(to, amount);
    _setExtraDataAt(startTokenId, joinSeriesAndEditionId(seriesId, editionId));
  }

  // Some extra view functions

  function getSeriesAndEdition(uint256 tokenId)
    external
    view
    override
    returns (uint16 seriesId, uint8 editionId)
  {
    (seriesId, editionId) = splitSeriesAndEditionId(
      _ownershipOf(tokenId).extraData
    );
  }

  function getBirthTime(uint256 tokenId)
    external
    view
    override
    returns (uint256)
  {
    return _ownershipOf(tokenId).startTimestamp;
  }

  // Overriding the tokenURI

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    require(_exists(tokenId), "NFB: Non-existent token");

    (uint16 seriesId, uint8 editionId) = splitSeriesAndEditionId(
      _ownershipOf(tokenId).extraData
    );

    require(
      address(tokenURIGetters[seriesId][editionId]) != address(0),
      "NFB: No tokenURI getter set"
    );

    return
      tokenURIGetters[seriesId][editionId].tokenURI(
        tokenId,
        seriesId,
        editionId
      );
  }

  // For metadata updating by the manager(s)

  function freezeSeries(uint16 id)
    external
    onlyRole(MANAGER_ROLE)
    seriesIsNotFrozen(id)
  {
    isSeriesFrozen[id] = true;
    emit SeriesFrozen(id);
  }

  function setTokenURIGetter(
    uint16 seriesId,
    uint8 editionId,
    INFBTokenURIGetter tokenURIGetter
  ) external onlyRole(MANAGER_ROLE) seriesIsNotFrozen(seriesId) {
    tokenURIGetters[seriesId][editionId] = tokenURIGetter;
    emit TokenURIGetterSet(seriesId, editionId, address(tokenURIGetter));
  }

  function setEdition(
    uint16 seriesId,
    uint8 id,
    uint256 availableFrom,
    uint256 availableUntil
  ) external onlyRole(MANAGER_ROLE) seriesIsNotFrozen(seriesId) {
    editions[seriesId][id] = Edition(availableFrom, availableUntil);
    emit EditionSet(seriesId, id, availableFrom, availableUntil);
  }

  function setSeries(
    uint16 id,
    string memory name,
    string memory description
  ) external onlyRole(MANAGER_ROLE) seriesIsNotFrozen(id) {
    series[id] = Series({description: description, name: name});
    emit SeriesSet(id, name, description);
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, IERC721A, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // Some utility functions

  function joinSeriesAndEditionId(uint16 seriesId, uint8 editionId)
    private
    pure
    returns (uint24 seriesAndEditionId)
  {
    // Shift the uint16 value left by 8 bits to make room for the uint8 value
    // Add the uint8 value to the uint24 value
    seriesAndEditionId = (seriesId << 8) | editionId;
  }

  function splitSeriesAndEditionId(uint24 seriesAndEditionId)
    private
    pure
    returns (uint16 seriesId, uint8 editionId)
  {
    // Mask the top 8 bits of the uint24 value to get the uint8 value
    editionId = uint8(seriesAndEditionId & 0xFF);
    // Shift the uint24 value right by 8 bits to get the uint16 value
    seriesId = uint16(seriesAndEditionId >> 8);
  }
}