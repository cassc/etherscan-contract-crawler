// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';

import '../../NFT/NFUToken.sol';

/**
 * @notice Clones an instance of NFUToken contract for a new owner.
 */
library NFUTokenFactory {
  /**
   * @notice In addition to taking the parameters requires by the NFUToken contract, the `_owner` argument will be used to assign ownership after contract deployment.
   *
   * @dev mintPeriodStart and mintPeriodEnd are set to 0 allowing immediate minting. These constrants can be set with a call to `updateMintPeriod`.
   *
   * @param _source Known-good deployment of NFUToken contract.
   */
  function createNFUToken(
    address _source,
    address payable _owner,
    CommonNFTAttributes memory _commonNFTAttributes,
    PermissionValidationComponents memory _permissionValidationComponents,
    IMintFeeOracle _feeOracle
  ) external returns (address token) {
    token = Clones.clone(_source);

    NFUToken(token).initialize(
      _owner,
      _commonNFTAttributes,
      _permissionValidationComponents,
      _feeOracle
    );
  }
}