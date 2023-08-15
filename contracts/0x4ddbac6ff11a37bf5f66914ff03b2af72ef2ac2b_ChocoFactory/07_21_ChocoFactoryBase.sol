// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "../interfaces/IChocoFactory.sol";

import "../utils/Revocable.sol";
import "../utils/TxValidatable.sol";

abstract contract ChocoFactoryBase is
  Initializable,
  ERC165Upgradeable,
  ContextUpgradeable,
  EIP712Upgradeable,
  Revocable,
  TxValidatable
{
  function initialize(string memory name, string memory version) public initializer {
    __EIP712_init_unchained(name, version);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IChocoFactory).interfaceId || super.supportsInterface(interfaceId);
  }

  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}