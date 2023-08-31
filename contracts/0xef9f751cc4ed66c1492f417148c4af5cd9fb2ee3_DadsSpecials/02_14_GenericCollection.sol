// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

        ████████████
      ██            ██
    ██              ██▓▓
    ██            ████▓▓▓▓▓▓
    ██      ██████▓▓▒▒▓▓▓▓▓▓▓▓
    ████████▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒
    ██    ████████▓▓▒▒▒▒▒▒▒▒▒▒
    ██            ██▓▓▒▒▒▒▒▒▒▒
    ██              ██▓▓▓▓▓▓▓▓
    ██    ██      ██    ██       '||''|.                    ||           '||
    ██                  ██        ||   ||  ... ..   ....   ...  .. ...    || ...    ...   ... ... ...
      ██              ██          ||'''|.   ||' '' '' .||   ||   ||  ||   ||'  || .|  '|.  ||  ||  |
        ██          ██            ||    ||  ||     .|' ||   ||   ||  ||   ||    | ||   ||   ||| |||
          ██████████             .||...|'  .||.    '|..'|' .||. .||. ||.  '|...'   '|..|'    |   |

*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @dev A general purpose ERC1155 collection.
 * Supports common royalty standards like OpenSea's contractURI and ERC2981.
 * Mint new works directly on the contract with mint() or grant the MINTER role to a
 * separate contract with more advanced functionality.
 */
contract GenericCollection is ERC1155, AccessControl {
  string public name;
  string public symbol;

  bytes32 private constant MINTER = keccak256("MINTER");

  mapping(uint256 => string) private _uris;
  string private _contractURI;

  address private _royaltiesReceiver;
  uint256 private _royaltiesPercentage;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory contractURI_,
    address royaltiesReceiver,
    uint256 royaltiesPercentage
  ) ERC1155("") {
    name = name_;
    symbol = symbol_;

    _contractURI = contractURI_;
    _royaltiesReceiver = royaltiesReceiver;
    _royaltiesPercentage = royaltiesPercentage;

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(MINTER, _msgSender());
  }

  // Access Control

  function grantMint(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(MINTER, account);
  }

  function revokeMint(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(MINTER, account);
  }

  // Minting

  function mint(
    uint256 id,
    uint256 amount,
    string memory tokenUri,
    address destination
  ) public onlyRole(MINTER) {
    setUri(id, tokenUri);
    _mint(destination, id, amount, "");
  }

  // Metadata

  function setUri(uint256 id, string memory tokenUri) public onlyRole(MINTER) {
    _uris[id] = tokenUri;
  }

  function uri(uint256 id) public view virtual override returns (string memory) {
    return _uris[id];
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory contractURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _contractURI = contractURI_;
  }

  // IERC2981

  function setRoyaltyInfo(address royaltiesReceiver, uint256 royaltiesPercentage) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _royaltiesReceiver = royaltiesReceiver;
    _royaltiesPercentage = royaltiesPercentage;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256 royaltyAmount) {
    tokenId; // silence solc warning
    royaltyAmount = (salePrice / 10000) * _royaltiesPercentage;
    return (_royaltiesReceiver, royaltyAmount);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || interfaceId == type(AccessControl).interfaceId || super.supportsInterface(interfaceId);
  }
}