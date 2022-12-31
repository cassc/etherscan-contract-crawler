// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../HasContractURI.sol";

contract ERC1155Base is
  Initializable,
  OwnableUpgradeable,
  ERC1155BurnableUpgradeable,
  ERC1155SupplyUpgradeable,
  ERC1155URIStorageUpgradeable,
  HasContractURI
{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  string public name;
  string public symbol;
  CountersUpgradeable.Counter private _tokenIds;

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Upgradeable, ERC165StorageUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  //SETUP URI

  function uri(uint256 _tokenId)
    public
    view
    override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)
    returns (string memory)
  {
    return super.uri(_tokenId);
  }

  function mint(
    address account,
    uint256 amount,
    string memory _tokenURI
  ) public onlyOwner {
    _tokenIds.increment();
    _minting(account, _tokenIds.current(), amount, _tokenURI);
  }

  function _minting(
    address account,
    uint256 _tokenId,
    uint256 amount,
    string memory _tokenURI
  ) internal {
    _mint(account, _tokenId, amount, "");
    _setURI(_tokenId, _tokenURI);
  }

  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function __ERC1155Base_init_unchained(
    string memory _name,
    string memory _symbol
  ) internal initializer {
    name = _name;
    symbol = _symbol;
  }
}