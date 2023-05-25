// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
                              ..............               ascii art by community member
                        ..::....          ....::..                           rqueue#4071
                    ..::..                        ::..
                  ::..                              ..--..
          ███████████████████████████████::..............::::..
          ██  ███  █  █        █  ███  ██                    ..::..
          ██  ██  ██  ████  ████  ███  ██                        ::::
          ██     ███  ████  ████       ██                          ..::
          ██  ██  ██  ████  ████  ███  ██                            ....
        ..██  ███  █  ████  ████  ███  ██                              ::
        ::███████████████████████████████                                ::
        ....    ::                                ....::::::::::..        ::
        --::......                    ..::==--::::....          ..::..    ....
      ::::  ..                  ..--..  [email protected]@++                      ::      ..
      ::                    ..------      ++..                        ..    ..
    ::                  ..::--------::  ::..    ::------..            ::::==++--..
  ....                ::----------------    ..**%%##****##==        --######++**##==
  ..              ::----------------..    ..####++..    --**++    ::####++::    --##==
....          ..----------------..        **##**          --##--::**##++..        --##::
..        ..--------------++==----------**####--          ..**++..::##++----::::::::****
..    ::==------------++##############%%######..            ++**    **++++++------==**##
::  ::------------++**::..............::**####..            ++**..::##..          ..++##
::....::--------++##..                  ::####::          ::****++####..          ..**++
..::  ::--==--==%%--                      **##++        ..--##++::####==          --##--
  ::..::----  ::==                        --####--..    ::**##..  ==%%##::      ::****
  ::      ::                                **####++--==####::      **%%##==--==####::
    ::    ..::..                    ....::::..--########++..          ==**######++..
      ::      ..::::::::::::::::::....      ..::::....                    ....
        ::::..                      ....::....
            ..::::::::::::::::::::....

*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract KithFriends is ERC1155, AccessControl, ERC1155Pausable {
  bytes32 public constant MINTER = keccak256("MINTER");

  string public name;
  string public symbol;
  string private _uri;

  mapping(uint256 => string) private _customURIs;
  string private _contractURI;

  address private _royaltiesReceiver;
  uint256 private _royaltiesPercentage;

  constructor(
    string memory initialBaseURI,
    string memory initialContractURI,
    address royalties
  ) ERC1155(initialBaseURI) {
    name = "Kith Friends";
    symbol = "KITHFRIENDS";

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(MINTER, _msgSender());

    setBaseURI(initialBaseURI);
    setContractURI(initialContractURI);
    setRoyaltyInfo(royalties, 750);
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
    address destination
  ) public onlyRole(MINTER) {
    _mint(destination, id, amount, "");
  }

  function mintCustom(
    uint256 id,
    uint256 amount,
    address destination,
    string memory tokenURI
  ) public onlyRole(MINTER) {
    setCustomURI(id, tokenURI);
    _mint(destination, id, amount, "");
  }

  // Metadata

  function uri(uint256 id) public view virtual override returns (string memory) {
    string memory customURI = _customURIs[id];

    if (keccak256(bytes(customURI)) != keccak256(bytes(""))) {
      return customURI;
    }

    return _uri;
  }

  function setCustomURI(uint256 id, string memory tokenURI) public onlyRole(MINTER) {
    _customURIs[id] = tokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _uri = baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory contractURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _contractURI = contractURI_;
  }

  // ERC1155Pausable

  function pause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Pausable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
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