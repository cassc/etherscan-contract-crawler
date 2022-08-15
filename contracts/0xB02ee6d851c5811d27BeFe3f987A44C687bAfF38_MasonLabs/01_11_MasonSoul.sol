// SPDX-License-Identifier: UNLICENSED

// ███╗   ███╗ █████╗ ██████╗ ███████╗   ██╗    ██╗██╗████████╗██╗  ██╗   ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝   ██║    ██║██║╚══██╔══╝██║  ██║   ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗     ██║ █╗ ██║██║   ██║   ███████║   ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝     ██║███╗██║██║   ██║   ██╔══██║   ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗   ╚███╔███╔╝██║   ██║   ██║  ██║   ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.15;

import "./mason/utils/AccessControl.sol";
import "./mason/utils/Soulbound.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { Base64 } from "./Base64.sol";
import { Utils } from "./Utils.sol";

error TokenDoesNotExist();

contract MasonLabs is Soulbound, AccessControl {
  string[] ROLE_NAMES = [
    "Advisor",
    "Alumni",
    "BFF",
    "Client",
    "Contractor",
    "Customer",
    "Employee",
    "Founder",
    "Friend",
    "Investor",
    "Partner"
  ];

  constructor(string memory _tokenName, string memory _tokenSymbol)
    ERC721A(_tokenName, _tokenSymbol)
  {}

  function issueToken(address _recipient, uint24 _role) external onlyOwner {
    _mint(_recipient, 1);
    _setExtraDataAt(_nextTokenId() - 1, _role);
  }

  function revokeToken(uint256 _tokenId) external onlyOwner {
    _burn(_tokenId);
  }

  function getRole(uint256 _tokenId) public view returns (uint24) {
    return _getRole(_tokenId);
  }

  function _getRole(uint256 _tokenId) public view returns (uint24) {
    return _ownershipOf(_tokenId).extraData;
  }

  function _getRoleName(uint roleId) public view returns (string memory) {
    return ROLE_NAMES[roleId];
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function collectionUri() public view returns (string memory _collectionUri) {}

  string private baseAssetUri = "https://arweave.net/7ea5IsiSjRjXyGYiiS-Y2iMYMhYxaSMJuNVXG_qRicw/";
  string private externalUrl = "https://madewithmason.com";
  string private tokenDescription = "This soulbound token is issued by Mason Labs and grants access to the ecosystem.";
  string private tokenName = "Mason Labs";

  function getBaseAssetUri() public view returns (string memory) {
    return baseAssetUri;
  }

  function getExternalUrl() public view returns (string memory) {
    return externalUrl;
  }

  function getTokenDescription() public view returns (string memory) {
    return tokenDescription;
  }

  function getTokenName() public view returns (string memory) {
    return tokenName;
  }

  function setBaseAssetUri(string memory _baseAssetUri) external onlyOwner {
    baseAssetUri = _baseAssetUri;
  }

  function setExternalUri(string memory _externalUrl) external onlyOwner {
    externalUrl = _externalUrl;
  }

  function setTokenDescription(string memory _tokenDescription) external onlyOwner {
    tokenDescription = _tokenDescription;
  }

  function setTokenName(string memory _tokenName) external onlyOwner {
    tokenName = _tokenName;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    if(!_exists(tokenId)) revert TokenDoesNotExist();

    string memory attributes;
    uint24 role = _getRole(tokenId);
    string memory roleName = _getRoleName(role);

    attributes = string(abi.encodePacked(
      '[ { "trait_type": "Type", "value": "',
      roleName,
      '"}]'));

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name": "',
                string.concat(tokenName, " - ", roleName),
                '", "description": "',
                tokenDescription,
                '", "external_url": "',
                externalUrl,
                '", "image":"',
                string.concat(baseAssetUri, Utils.uintToString(role), ".png"),
                '", "animation_url":"',
                string.concat(baseAssetUri, Utils.uintToString(role), ".mp4"),
                '", "attributes":',
                attributes,
                '}'
              )
            )
          )
        )
      );
  }
}