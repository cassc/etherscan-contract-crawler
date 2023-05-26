// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SwampverseERC721.sol";

interface ICroakens {
  function update(address from, address to) external;
  function burn(address from, uint256 amount) external;
}

contract Swampverse is SwampverseERC721 {
  using Address for address;

  struct SwamperInfo {
    string name;
    string description;
  }

  event UpdateName(uint256 indexed tokenId, string name);
  event UpdateDescription(uint256 indexed tokenId, string description);

  uint256 constant public UPDATE_NAME_PRICE = 100 ether;
  uint256 constant public UPDATE_DESCRIPTION_PRICE = 100 ether;

  ICroakens public Croakens;
  mapping(uint256 => SwamperInfo) public swamperInfo;

  constructor(
    address team,
    address signer,
    string memory baseTokenURI,
    address vrfCoordinator,
    address linkToken,
    bytes32 keyHash,
    uint256 linkFee
  )
    SwampverseERC721(
      team,
      signer,
      baseTokenURI,
      vrfCoordinator,
      linkToken,
      keyHash,
      linkFee
    )
  {}

  modifier onlyTokenOwner(uint256 tokenId) {
    require(ownerOf(tokenId) == msg.sender, "Sender is not the token owner");
    _;
  }

  function setCroakensAddress(address croakens) public onlyOwner {
    Croakens = ICroakens(croakens);
  }

  function updateName(uint256 tokenId, string calldata name)
    public
    onlyTokenOwner(tokenId)
  {
    require(address(Croakens) != address(0), "No token contract set");

    bytes memory n = bytes(name);
    require(n.length > 0 && n.length < 25, "Invalid name length");
    require(
      sha256(n) != sha256(bytes(swamperInfo[tokenId].name)),
      "New name is same as current name"
    );

    Croakens.burn(msg.sender, UPDATE_NAME_PRICE);
    swamperInfo[tokenId].name = name;
    emit UpdateName(tokenId, name);
  }

  function updateDescription(uint256 tokenId, string calldata description)
    public
    onlyTokenOwner(tokenId)
  {
    require(address(Croakens) != address(0), "No token contract set");

    bytes memory d = bytes(description);
    require(d.length > 0 && d.length < 280, "Invalid description length");
    require(
      sha256(bytes(d)) != sha256(bytes(swamperInfo[tokenId].description)),
      "New description is same as current description"
    );

    Croakens.burn(msg.sender, UPDATE_DESCRIPTION_PRICE);
    swamperInfo[tokenId].description = description;
    emit UpdateDescription(tokenId, description);
  }

  function transferFrom(address from, address to, uint256 tokenId)
    public
    override
    nonReentrant
  {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

    if (address(Croakens) != address(0)) {
      Croakens.update(from, to);
    }

    ERC721.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    nonReentrant
  {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

    if (address(Croakens) != address(0)) {
      Croakens.update(from, to);
    }

    ERC721.safeTransferFrom(from, to, tokenId, data);
  }
}