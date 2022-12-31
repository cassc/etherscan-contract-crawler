// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC721Base.sol";

contract ERC721VCG is ERC721Base {
  event CreateERC721VCG(address owner, string name, string symbol);

  function __ERC721VCG_init(
    string memory _name,
    string memory _symbol,
    string memory _contractURI
  ) external initializer {
    __ERC721VCG_init_unchained(_name, _symbol, _contractURI);
    emit CreateERC721VCG(_msgSender(), _name, _symbol);
  }

  function __ERC721VCG_init_unchained(
    string memory _name,
    string memory _symbol,
    string memory _contractURI
  ) internal {
    __Ownable_init_unchained();
    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721Royalty_init_unchained();
    __ERC721Burnable_init_unchained();
    __HasContractURI_init_unchained(_contractURI);
    __ERC721_init_unchained(_name, _symbol);
  }

  uint256[50] private __gap;
}