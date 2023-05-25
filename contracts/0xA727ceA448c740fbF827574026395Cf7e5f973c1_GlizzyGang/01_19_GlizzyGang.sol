// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./GlizzyGangERC721.sol";

interface IMustard {
  function migrate(address to, uint256 amount) external;
  function update(address from, address to) external;
  function burn(address from, uint256 amount) external;
}

contract GlizzyGang is GlizzyGangERC721 {
  using Address for address;

  struct GlizzyInfo {
    string name;
    string description;
  }

  event Migrated(uint256 tokenId);
  event UpdateName(uint256 indexed tokenId, string name);
  event UpdateDescription(uint256 indexed tokenId, string description);

  uint256 constant public UPDATE_NAME_PRICE = 100 ether;
  uint256 constant public UPDATE_DESCRIPTION_PRICE = 100 ether;

  IMustard public Mustard;
  IERC1155 public OpenSeaStore;
  mapping(uint256 => GlizzyInfo) public glizzyInfo;

  constructor(
    address signer,
    address openSeaStore,
    string memory placeholderURI,
    address vrfCoordinator,
    address linkToken,
    bytes32 keyHash,
    uint256 linkFee
  )
    GlizzyGangERC721(
      signer,
      placeholderURI,
      vrfCoordinator,
      linkToken,
      keyHash,
      linkFee
    )
  {
    OpenSeaStore = IERC1155(openSeaStore);
  }

  modifier onlyTokenOwner(uint256 tokenId) {
    require(ownerOf(tokenId) == msg.sender, "Sender is not the token owner");
    _;
  }

  function setMustardAddress(address mustard) public onlyOwner {
    Mustard = IMustard(mustard);
  }

  function updateName(uint256 tokenId, string calldata name)
    public
    onlyTokenOwner(tokenId)
  {
    require(address(Mustard) != address(0), "No token contract set");

    bytes memory n = bytes(name);
    require(n.length > 0 && n.length < 25, "Invalid name length");
    require(
      sha256(n) != sha256(bytes(glizzyInfo[tokenId].name)),
      "New name is same as current name"
    );

    Mustard.burn(msg.sender, UPDATE_NAME_PRICE);
    glizzyInfo[tokenId].name = name;
    emit UpdateName(tokenId, name);
  }

  function updateDescription(uint256 tokenId, string calldata description)
    public
    onlyTokenOwner(tokenId)
  {
    require(address(Mustard) != address(0), "No token contract set");

    bytes memory d = bytes(description);
    require(d.length > 0 && d.length < 280, "Invalid description length");
    require(
      sha256(bytes(d)) != sha256(bytes(glizzyInfo[tokenId].description)),
      "New description is same as current description"
    );

    Mustard.burn(msg.sender, UPDATE_DESCRIPTION_PRICE);
    glizzyInfo[tokenId].description = description;
    emit UpdateDescription(tokenId, description);
  }

  function _getGlizzyId(uint256 _id) pure internal returns (uint256) {
    require(_id >> 96 == 0x0000000000000000000000002507f5f7622cc7097630dd6e060719e063778b2b, "Invalid token");
    require(_id & 0x000000000000000000000000000000000000000000000000000000ffffffffff == 1, "Invalid token");

    _id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;

    require(_id > 0 && _id <= 251, "Invalid token");

    // match token IDs to OpenSea collection display IDs
    if (_id == 251) return 0;
    else if (_id == 200) return 46;
    else if (_id >= 46 && _id < 200) return _id + 1;
    else return _id;
  }

  function migrate(uint256 _tokenId) nonReentrant external {
    uint256 id = _getGlizzyId(_tokenId);

    OpenSeaStore.safeTransferFrom(
      msg.sender,
      address(0x000000000000000000000000000000000000dEaD),
      _tokenId,
      1,
      ""
    );

    Mustard.migrate(msg.sender, 1);
    Mustard.update(address(0), msg.sender);

    _mint(msg.sender, id);

    emit Migrated(id);
  }

  function transferFrom(address from, address to, uint256 tokenId)
    public
    override
    nonReentrant
  {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

    if (address(Mustard) != address(0)) {
      Mustard.update(from, to);
    }

    ERC721.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    nonReentrant
  {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

    if (address(Mustard) != address(0)) {
      Mustard.update(from, to);
    }

    ERC721.safeTransferFrom(from, to, tokenId, data);
  }
}