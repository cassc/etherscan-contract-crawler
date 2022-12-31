// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC1155Base.sol";

contract ERC1155VCG is ERC1155Base {
  event CreateERC1155VCG(address owner, string name, string symbol);

  function __ERC1155VCG_init(
    string memory _name,
    string memory _symbol,
    string memory _contractURI
  ) external initializer {
    __ERC1155VCG_init_unchained(_name, _symbol, _contractURI);
    emit CreateERC1155VCG(_msgSender(), _name, _symbol);
  }

  function __ERC1155VCG_init_unchained(
    string memory _name,
    string memory _symbol,
    string memory _contractURI
  ) internal {
    __ERC1155_init("");
    __Ownable_init();
    __ERC1155Burnable_init();
    __ERC1155Supply_init();
    __ERC1155Base_init_unchained(_name, _symbol);
    __HasContractURI_init_unchained(_contractURI);
  }

  uint256[50] private __gap;
}