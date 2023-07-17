// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import '../../ThinProjectPayer.sol';
import '../../../interfaces/IJBProjectPayer.sol';

library ThinProjectPayerFactory {
  error INVALID_SOURCE_CONTRACT();

  function createProjectPayer(
    address payable _source,
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    uint256 _projectId,
    address payable _defaultBeneficiary,
    bool _preferClaimedTokens,
    bool _preferAddToBalance,
    string memory _memo,
    bytes memory _metadata
  ) public returns (address payable payerClone) {
    if (!IERC165(_source).supportsInterface(type(IJBProjectPayer).interfaceId)) {
      revert INVALID_SOURCE_CONTRACT();
    }

    payerClone = payable(Clones.clone(address(_source)));
    ThinProjectPayer(payerClone).initialize(
      _jbxDirectory,
      _jbxOperatorStore,
      _jbxProjects,
      _projectId,
      _defaultBeneficiary,
      _preferClaimedTokens,
      _preferAddToBalance,
      _memo,
      _metadata
    );
  }
}