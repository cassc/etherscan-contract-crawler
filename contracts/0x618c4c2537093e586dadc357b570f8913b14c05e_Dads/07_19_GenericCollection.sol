// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
                                                                         ▄▄▄██
 ████████████████▄▄▄▄                                               ▄█████████
  █████████▀▀▀▀█████████▄                                            ▀████████
  ▐███████▌       ▀████████▄                                          ▐███████
  ▐███████▌         █████████▄                                        ▐███████
  ▐███████▌          ▀████████▌         ▄▄▄▄                    ▄▄▄   ▐███████          ▄▄▄▄
  ▐███████▌           █████████▌   ▄█████▀▀█████▄▄         ▄█████▀▀███████████     ▄█████▀▀██████▄
  ▐███████▌            █████████ ▐██████    ▐██████▄     ▄█████▌     ▀████████   ▄██████    ▐██████
  ▐███████▌            █████████ ▐█████      ███████▌   ███████       ████████  ▐███████▌    ▀█████
  ▐███████▌            ▐████████       ▄▄▄▄  ▐███████  ▐███████       ▐███████   ██████████▄▄
  ▐███████▌            ▐███████▌   ▄███████▀█████████  ████████       ▐███████    ██████████████▄▄
  ▐███████▌            ███████▌  ▄███████    ▐███████▌ ▐███████       ▐███████      ▀▀█████████████
  ▐███████▌           ▄██████▀   ████████     ████████  ████████      ▐███████   ████▄    ▀▀███████▌
  ▐████████▄        ▄██████▀     ████████     ████████   ███████▌     ▐███████  ███████     ▐██████▌
 ▄██████████████████████▀         ▀███████▄  ▄█████████▄  ▀███████▄  ▄█████████  ▀██████▄   ██████▀
 ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀                ▀▀▀████▀▀▀  ▀▀▀▀▀▀▀▀     ▀▀▀████▀▀  ▀▀▀▀▀▀▀▀    ▀▀▀▀████▀▀▀▀

*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract GenericCollection is ERC1155, AccessControl, ERC2981 {
  string public name;
  string public symbol;
  string private _uri;

  bytes32 public constant MINTWORTHY = keccak256("MINTWORTHY");

  mapping(uint256 => string) private _customURIs;
  string private _contractURI;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory initialBaseURI,
    string memory initialContractURI,
    address payable royaltiesReceiver,
    uint96 royaltiesNumerator
  ) ERC1155("") {
    name = name_;
    symbol = symbol_;

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(MINTWORTHY, _msgSender());

    setBaseURI(initialBaseURI);
    setContractURI(initialContractURI);
    setRoyaltyInfo(royaltiesReceiver, royaltiesNumerator);
  }

  // Minting

  function mint(
    uint256 id,
    uint256 amount,
    address destination
  ) public onlyRole(MINTWORTHY) {
    _mint(destination, id, amount, "");
  }

  function mint(
    uint256 id,
    uint256 amount,
    address destination,
    string memory tokenUri
  ) public onlyRole(MINTWORTHY) {
    setCustomUri(id, tokenUri);
    _mint(destination, id, amount, "");
  }

  // Metadata

  function setBaseURI(string memory baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _uri = baseURI;
  }

  function setCustomUri(uint256 id, string memory tokenUri) public onlyRole(MINTWORTHY) {
    _customURIs[id] = tokenUri;
  }

  function uri(uint256 id) public view virtual override returns (string memory) {
    string memory customURI = _customURIs[id];

    if (keccak256(bytes(customURI)) != keccak256(bytes(""))) {
      return customURI;
    }

    return _uri;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory contractURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _contractURI = contractURI_;
  }

  // IERC2981

  function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setDefaultRoyalty(receiver, numerator);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981, AccessControl) returns (bool) {
    return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
  }
}