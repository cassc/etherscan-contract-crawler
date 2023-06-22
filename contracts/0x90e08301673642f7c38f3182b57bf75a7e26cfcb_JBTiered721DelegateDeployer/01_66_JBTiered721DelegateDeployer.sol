// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './interfaces/IJBTiered721DelegateDeployer.sol';
import './JBTiered721Delegate.sol';
import './JB721TieredGovernance.sol';
import './JB721GlobalGovernance.sol';

/**
  @notice
  Deploys a tier delegate.

  @dev
  Adheres to -
  IJBTiered721DelegateDeployer: General interface for the generic controller methods in this contract that interacts with funding cycles and tokens according to the protocol's rules.
*/
contract JBTiered721DelegateDeployer is IJBTiered721DelegateDeployer {
  error INVALID_GOVERNANCE_TYPE();

  uint256 constant DEPLOY_BYTECODE_LENGTH = 13;

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /** 
    @notice 
    The contract that supports on-chain governance across all tiers. 
  */
  JB721GlobalGovernance public immutable globalGovernance;

  /** 
    @notice 
    The contract that supports on-chain governance per-tier. 
  */
  JB721TieredGovernance public immutable tieredGovernance;

  /** 
    @notice 
    The contract that has no on-chain governance. 
  */
  JBTiered721Delegate public immutable noGovernance;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  constructor(
    JB721GlobalGovernance _globalGovernance,
    JB721TieredGovernance _tieredGovernance,
    JBTiered721Delegate _noGovernance
  ) {
    globalGovernance = _globalGovernance;
    tieredGovernance = _tieredGovernance;
    noGovernance = _noGovernance;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Deploys a delegate.

    @param _projectId The ID of the project this contract's functionality applies to.
    @param _deployTiered721DelegateData Data necessary to fulfill the transaction to deploy a delegate.

    @return newDelegate The address of the newly deployed delegate.
  */
  function deployDelegateFor(
    uint256 _projectId,
    JBDeployTiered721DelegateData memory _deployTiered721DelegateData
  ) external override returns (IJBTiered721Delegate newDelegate) {
    // Deploy the governance variant that was requested
    address codeToCopy;
    if (_deployTiered721DelegateData.governanceType == JB721GovernanceType.NONE)
      codeToCopy = address(noGovernance);
    else if (_deployTiered721DelegateData.governanceType == JB721GovernanceType.TIERED)
      codeToCopy = address(tieredGovernance);
    else if (_deployTiered721DelegateData.governanceType == JB721GovernanceType.GLOBAL)
      codeToCopy = address(globalGovernance);
    else revert INVALID_GOVERNANCE_TYPE();

    newDelegate = IJBTiered721Delegate(_clone(codeToCopy));
    newDelegate.initialize(
      _projectId,
      _deployTiered721DelegateData.directory,
      _deployTiered721DelegateData.name,
      _deployTiered721DelegateData.symbol,
      _deployTiered721DelegateData.fundingCycleStore,
      _deployTiered721DelegateData.baseUri,
      _deployTiered721DelegateData.tokenUriResolver,
      _deployTiered721DelegateData.contractUri,
      _deployTiered721DelegateData.pricing,
      _deployTiered721DelegateData.store,
      _deployTiered721DelegateData.flags
    );

    // Transfer the ownership to the specified address.
    if (_deployTiered721DelegateData.owner != address(0))
      Ownable(address(newDelegate)).transferOwnership(_deployTiered721DelegateData.owner);

    emit DelegateDeployed(_projectId, newDelegate, _deployTiered721DelegateData.governanceType);

    return newDelegate;
  }

  /**
    @notice Clone and redeploy the bytecode of a given address

    @dev Runtime bytecode needs a constructor -> we append this one
         to the bytecode, which is a minimalistic one only returning the runtime bytecode

         See https://github.com/drgorillamd/clone-deployed-contract/blob/master/readme.MD for details
   */
  function _clone(address _targetAddress) internal returns (address _out) {
    assembly {
      // Get deployed/runtime code size
      let _codeSize := extcodesize(_targetAddress)

      // Get a bit of freemem to land the bytecode, not updated as we'll leave this scope right after create(..)
      let _freeMem := mload(0x40)

      // Shift the length to the length placeholder, in the constructor (by adding zero's/mul)
      let _mask := mul(_codeSize, 0x100000000000000000000000000000000000000000000000000000000)

      // Insert the length in the correct spot (after the PUSH3 / 0x62)
      let _initCode := or(_mask, 0x62000000600081600d8239f3fe00000000000000000000000000000000000000)
      // --------------------------- here ^ (see the "1" from the mul step aligning)

      // Store the deployment bytecode in free memory
      mstore(_freeMem, _initCode)

      // Copy the bytecode, after the deployer bytecode in free memory
      extcodecopy(_targetAddress, add(_freeMem, DEPLOY_BYTECODE_LENGTH), 0, _codeSize)

      // Deploy the copied bytecode (constructor + original) and return the address in 'out'
      _out := create(0, _freeMem, add(_codeSize, DEPLOY_BYTECODE_LENGTH))
    }
  }
}