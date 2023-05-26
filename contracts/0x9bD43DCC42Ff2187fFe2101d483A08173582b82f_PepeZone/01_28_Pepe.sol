// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../Standard.sol";

import "../../external/ENS.sol";
import "../../external/PublicResolver.sol";

contract PepeZone is StandardZone {
  using Strings for uint256;

  event EnsOriginSet(bytes32 indexed ensOrigin);

  ENS public ens;
  PublicResolver public resolver;

  bool public avatar;
  bytes32 public ensOrigin;

  mapping (uint256 => bytes32) public idToLabel;

  constructor(ENS _registry, PublicResolver _resolver)
    StandardZone(
      msg.sender,
      hex"5b0ff7c1d5683bef738838377aa985128bbc5c6d2c0aaa42cd72a1a09c34e624",
      ".pepe",
      "PEPE",
      "ipfs://"
    )
  {
    ens = _registry;
    resolver = _resolver;
  }

  function _transfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override {

    super._transfer(from, to, tokenId);

    if(idToLabel[tokenId] != 0x0 && ens.owner(keccak256(abi.encodePacked(ensOrigin, idToLabel[tokenId]))) == from){
      bytes32 subnode = ens.setSubnodeOwner(ensOrigin, idToLabel[tokenId], address(this));
      ens.setOwner(subnode, to);
    }
  }

  function register(
    address to,
    bytes32 parent,
    string memory label
  ) public virtual override returns (bytes32 namehash) {
    require(
      _isApprovedOrOwner(_msgSender(), uint256(parent)),
      "must own parent"
    );
    require(_isValidLabel(bytes(label)), "invalid label");

    bytes32 _label = keccak256(bytes(label));
    namehash = _register(to, parent, _label);

    emit ResourceRegistered(parent, label);
  }

  function _register(
    address to,
    bytes32 parent,
    bytes32 label
  ) internal virtual returns (bytes32 namehash) {
    namehash = keccak256(abi.encodePacked(parent, label));

    if (parent == getOrigin()) {
      bytes32 subnode = ens.setSubnodeOwner(ensOrigin, label, address(this));
      resolver.setAddr(subnode, to);

      if (avatar) {
        string memory urn = _generateUrn(namehash);
        resolver.setText(subnode, "avatar", urn);
      }

      ens.setResolver(subnode, address(resolver));
      ens.setOwner(subnode, to);
    }
    _safeMint(to, uint256(namehash));
    idToLabel[uint256(namehash)] = label;
  }

  function mapZone(string memory label, string memory tld) external {
    require(
      _isApprovedOrOwner(_msgSender(), uint256(getOrigin())),
      "must own zone"
    );

    ensOrigin = keccak256(
      abi.encodePacked(
        keccak256(abi.encodePacked(bytes32(0x0), keccak256(bytes(tld)))),
        keccak256(bytes(label))
      )
    );

    emit EnsOriginSet(ensOrigin);
  }

  function _generateUrn(bytes32 domain)
    internal
    view
    returns (string memory urn)
  {
    string memory addr = uint256(uint160(address(this))).toHexString(20);
    string memory tokenId = uint256(domain).toString();
    urn = string(abi.encodePacked("eip155:1/erc721:", addr, "/", tokenId));
  }

  function setAvatar(bool enabled) external {
    require(
      _isApprovedOrOwner(_msgSender(), uint256(getOrigin())),
      "must own zone"
    );
    avatar = enabled;
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
    require(
      _isApprovedOrOwner(_msgSender(), uint256(getOrigin())),
      "must own zone"
    );
    _setTokenURI(tokenId, _tokenURI);
  }
}