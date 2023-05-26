// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol
contract STJT721 is ERC721, AccessControl {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  string public baseUri;
  address public owner;
  constructor(string memory _name, string memory _symbol, string memory _baseUri) ERC721(_name, _symbol) {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(BURNER_ROLE, _msgSender());
      owner = _msgSender();
      baseUri = _baseUri;
  }

  function setBaseURI(string memory _baseURIString) external onlyRole(DEFAULT_ADMIN_ROLE) {
      baseUri = _baseURIString;
  }

  function _baseURI() internal override view  returns (string memory) {
    return baseUri;
  }

  function mint(address _to, uint256 _tokenId) external onlyRole(MINTER_ROLE) {
    _mint(_to, _tokenId);
  }

  function burn(uint256 _tokenId) external onlyRole(BURNER_ROLE) {
    _burn(_tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}