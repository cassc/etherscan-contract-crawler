// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import '../../NFT/TraitToken.sol';

library TraitTokenFactory {
  error INVALID_SOURCE_CONTRACT();

  function createTraitToken(
    address _source,
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseUri,
    string memory _contractUri,
    uint256 _maxSupply,
    uint256 _unitPrice,
    uint256 _mintAllowance
  ) public returns (address tokenClone) {
    if (!IERC165(_source).supportsInterface(type(ITraitToken).interfaceId)) {
      revert INVALID_SOURCE_CONTRACT();
    }

    tokenClone = Clones.clone(_source);
    TraitToken(tokenClone).initialize(
      _owner,
      _name,
      _symbol,
      _baseUri,
      _contractUri,
      _maxSupply,
      _unitPrice,
      _mintAllowance,
      0,
      0
    );
  }
}