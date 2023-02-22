// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@jbx-protocol/juice-contracts-v3/contracts/abstract/JBOperatable.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBOperations.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycleMetadata.sol';
import './interfaces/IJBTiered721DelegateProjectDeployer.sol';

/**
  @notice
  Deploys a project with a tiered tier delegate.

  @dev
  Adheres to -
  IJBTiered721DelegateProjectDeployer: General interface for the generic controller methods in this contract that interacts with funding cycles and tokens according to the protocol's rules.

  @dev
  Inherits from -
  JBOperatable: Several functions in this contract can only be accessed by a project owner, or an address that has been preconfigured to be an operator of the project.
*/
contract JBTiered721DelegateProjectDeployer is JBOperatable, IJBTiered721DelegateProjectDeployer {
  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /**
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  /** 
    @notice
    The contract responsible for deploying the delegate. 
  */
  IJBTiered721DelegateDeployer public immutable override delegateDeployer;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _directory The directory of terminals and controllers for projects.
    @param _delegateDeployer The deployer of delegates.
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(
    IJBDirectory _directory,
    IJBTiered721DelegateDeployer _delegateDeployer,
    IJBOperatorStore _operatorStore
  ) JBOperatable(_operatorStore) {
    directory = _directory;
    delegateDeployer = _delegateDeployer;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Launches a new project with a tiered 721 delegate attached.

    @param _owner The address to set as the owner of the project. The project ERC-721 will be owned by this address.
    @param _deployTiered721DelegateData Data necessary to fulfill the transaction to deploy a delegate.
    @param _launchProjectData Data necessary to fulfill the transaction to launch a project.
    @param _controller The controller with which the funding cycles should be configured.

    @return projectId The ID of the newly configured project.
  */
  function launchProjectFor(
    address _owner,
    JBDeployTiered721DelegateData memory _deployTiered721DelegateData,
    JBLaunchProjectData memory _launchProjectData,
    IJBController3_1 _controller
  ) external override returns (uint256 projectId) {
    // Get the project ID, optimistically knowing it will be one greater than the current count.
    projectId = directory.projects().count() + 1;

    // Deploy the delegate contract.
    IJBTiered721Delegate _delegate = delegateDeployer.deployDelegateFor(
      projectId,
      _deployTiered721DelegateData,
      directory
    );

    // Launch the project.
    _launchProjectFor(_owner, _launchProjectData, _delegate, _controller);
  }

  /**
    @notice
    Launches funding cycle's for a project with a delegate attached.

    @dev
    Only a project owner or operator can launch its funding cycles.

    @param _projectId The ID of the project having funding cycles launched.
    @param _deployTiered721DelegateData Data necessary to fulfill the transaction to deploy a delegate.
    @param _launchFundingCyclesData Data necessary to fulfill the transaction to launch funding cycles for the project.
    @param _controller The controller with which the funding cycles should be configured.

    @return configuration The configuration of the funding cycle that was successfully created.
  */
  function launchFundingCyclesFor(
    uint256 _projectId,
    JBDeployTiered721DelegateData memory _deployTiered721DelegateData,
    JBLaunchFundingCyclesData memory _launchFundingCyclesData,
    IJBController3_1 _controller
  )
    external
    override
    requirePermission(
      directory.projects().ownerOf(_projectId),
      _projectId,
      JBOperations.RECONFIGURE
    )
    returns (uint256 configuration)
  {
    // Deploy the delegate contract.
    IJBTiered721Delegate _delegate = delegateDeployer.deployDelegateFor(
      _projectId,
      _deployTiered721DelegateData,
      directory
    );

    // Launch the funding cycles.
    return _launchFundingCyclesFor(_projectId, _launchFundingCyclesData, _delegate, _controller);
  }

  /**
    @notice
    Reconfigures funding cycles for a project with a delegate attached.

    @dev
    Only a project's owner or a designated operator can configure its funding cycles.

    @param _projectId The ID of the project having funding cycles reconfigured.
    @param _deployTiered721DelegateData Data necessary to fulfill the transaction to deploy a delegate.
    @param _reconfigureFundingCyclesData Data necessary to fulfill the transaction to reconfigure funding cycles for the project.
    @param _controller The controller with which the funding cycles should be configured.

    @return configuration The configuration of the funding cycle that was successfully reconfigured.
  */
  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBDeployTiered721DelegateData memory _deployTiered721DelegateData,
    JBReconfigureFundingCyclesData memory _reconfigureFundingCyclesData,
    IJBController3_1 _controller
  )
    external
    override
    requirePermission(
      directory.projects().ownerOf(_projectId),
      _projectId,
      JBOperations.RECONFIGURE
    )
    returns (uint256 configuration)
  {
    // Deploy the delegate contract.
    IJBTiered721Delegate _delegate = delegateDeployer.deployDelegateFor(
      _projectId,
      _deployTiered721DelegateData,
      directory
    );

    // Reconfigure the funding cycles.
    return _reconfigureFundingCyclesOf(_projectId, _reconfigureFundingCyclesData, _delegate, _controller);
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /** 
    @notice
    Launches a project.

    @param _owner The address to set as the owner of the project. 
    @param _launchProjectData Data necessary to fulfill the transaction to launch the project.
    @param _dataSource The data source to set.
    @param _controller The controller with which the funding cycles should be configured.
  */
  function _launchProjectFor(
    address _owner,
    JBLaunchProjectData memory _launchProjectData,
    IJBTiered721Delegate _dataSource,
    IJBController3_1 _controller
  ) internal {
    _controller.launchProjectFor(
      _owner,
      _launchProjectData.projectMetadata,
      _launchProjectData.data,
      JBFundingCycleMetadata({
        global: _launchProjectData.metadata.global,
        reservedRate: _launchProjectData.metadata.reservedRate,
        redemptionRate: _launchProjectData.metadata.redemptionRate,
        ballotRedemptionRate: _launchProjectData.metadata.ballotRedemptionRate,
        pausePay: _launchProjectData.metadata.pausePay,
        pauseDistributions: _launchProjectData.metadata.pauseDistributions,
        pauseRedeem: _launchProjectData.metadata.pauseRedeem,
        pauseBurn: _launchProjectData.metadata.pauseBurn,
        allowMinting: _launchProjectData.metadata.allowMinting,
        allowTerminalMigration: _launchProjectData.metadata.allowTerminalMigration,
        allowControllerMigration: _launchProjectData.metadata.allowControllerMigration,
        holdFees: _launchProjectData.metadata.holdFees,
        preferClaimedTokenOverride: _launchProjectData.metadata.preferClaimedTokenOverride,
        useTotalOverflowForRedemptions: _launchProjectData.metadata.useTotalOverflowForRedemptions,
        // Set the project to use the data source for its pay function.
        useDataSourceForPay: true,
        useDataSourceForRedeem: _launchProjectData.metadata.useDataSourceForRedeem,
        // Set the delegate address as the data source of the provided metadata.
        dataSource: address(_dataSource),
        metadata: _launchProjectData.metadata.metadata
      }),
      _launchProjectData.mustStartAtOrAfter,
      _launchProjectData.groupedSplits,
      _launchProjectData.fundAccessConstraints,
      _launchProjectData.terminals,
      _launchProjectData.memo
    );
  }

  /**
    @notice
    Launches funding cycles for a project.

    @param _projectId The ID of the project having funding cycles launched.
    @param _launchFundingCyclesData Data necessary to fulfill the transaction to launch funding cycles for the project.
    @param _dataSource The data source to set.
    @param _controller The controller with which the funding cycles should be configured.

    @return configuration The configuration of the funding cycle that was successfully created.
  */
  function _launchFundingCyclesFor(
    uint256 _projectId,
    JBLaunchFundingCyclesData memory _launchFundingCyclesData,
    IJBTiered721Delegate _dataSource,
    IJBController3_1 _controller
  ) internal returns (uint256) {
    return
      _controller.launchFundingCyclesFor(
        _projectId,
        _launchFundingCyclesData.data,
        JBFundingCycleMetadata({
          global: _launchFundingCyclesData.metadata.global,
          reservedRate: _launchFundingCyclesData.metadata.reservedRate,
          redemptionRate: _launchFundingCyclesData.metadata.redemptionRate,
          ballotRedemptionRate: _launchFundingCyclesData.metadata.ballotRedemptionRate,
          pausePay: _launchFundingCyclesData.metadata.pausePay,
          pauseDistributions: _launchFundingCyclesData.metadata.pauseDistributions,
          pauseRedeem: _launchFundingCyclesData.metadata.pauseRedeem,
          pauseBurn: _launchFundingCyclesData.metadata.pauseBurn,
          allowMinting: _launchFundingCyclesData.metadata.allowMinting,
          allowTerminalMigration: _launchFundingCyclesData.metadata.allowTerminalMigration,
          allowControllerMigration: _launchFundingCyclesData.metadata.allowControllerMigration,
          holdFees: _launchFundingCyclesData.metadata.holdFees,
          preferClaimedTokenOverride: _launchFundingCyclesData.metadata.preferClaimedTokenOverride,
          useTotalOverflowForRedemptions: _launchFundingCyclesData.metadata.useTotalOverflowForRedemptions,
          // Set the project to use the data source for its pay function.
          useDataSourceForPay: true,
          useDataSourceForRedeem: _launchFundingCyclesData.metadata.useDataSourceForRedeem,
          // Set the delegate address as the data source of the provided metadata.
          dataSource: address(_dataSource),
          metadata: _launchFundingCyclesData.metadata.metadata
        }),
        _launchFundingCyclesData.mustStartAtOrAfter,
        _launchFundingCyclesData.groupedSplits,
        _launchFundingCyclesData.fundAccessConstraints,
        _launchFundingCyclesData.terminals,
        _launchFundingCyclesData.memo
      );
  }

  /**
    @notice
    Reconfigure funding cycles for a project.

    @param _projectId The ID of the project having funding cycles launched.
    @param _reconfigureFundingCyclesData Data necessary to fulfill the transaction to launch funding cycles for the project.
    @param _dataSource The data source to set.
    @param _controller The controller with which the funding cycles should be configured.

    @return The configuration of the funding cycle that was successfully reconfigured.
  */
  function _reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBReconfigureFundingCyclesData memory _reconfigureFundingCyclesData,
    IJBTiered721Delegate _dataSource,
    IJBController3_1 _controller
  ) internal returns (uint256) {
    return
      _controller.reconfigureFundingCyclesOf(
        _projectId,
        _reconfigureFundingCyclesData.data,
        JBFundingCycleMetadata({
          global: _reconfigureFundingCyclesData.metadata.global,
          reservedRate: _reconfigureFundingCyclesData.metadata.reservedRate,
          redemptionRate: _reconfigureFundingCyclesData.metadata.redemptionRate,
          ballotRedemptionRate: _reconfigureFundingCyclesData.metadata.ballotRedemptionRate,
          pausePay: _reconfigureFundingCyclesData.metadata.pausePay,
          pauseDistributions: _reconfigureFundingCyclesData.metadata.pauseDistributions,
          pauseRedeem: _reconfigureFundingCyclesData.metadata.pauseRedeem,
          pauseBurn: _reconfigureFundingCyclesData.metadata.pauseBurn,
          allowMinting: _reconfigureFundingCyclesData.metadata.allowMinting,
          allowTerminalMigration: _reconfigureFundingCyclesData.metadata.allowTerminalMigration,
          allowControllerMigration: _reconfigureFundingCyclesData.metadata.allowControllerMigration,
          holdFees: _reconfigureFundingCyclesData.metadata.holdFees,
          preferClaimedTokenOverride: _reconfigureFundingCyclesData.metadata.preferClaimedTokenOverride,
          useTotalOverflowForRedemptions: _reconfigureFundingCyclesData.metadata.useTotalOverflowForRedemptions,
          // Set the project to use the data source for its pay function.
          useDataSourceForPay: true,
          useDataSourceForRedeem: _reconfigureFundingCyclesData.metadata.useDataSourceForRedeem,
          // Set the delegate address as the data source of the provided metadata.
          dataSource: address(_dataSource),
          metadata: _reconfigureFundingCyclesData.metadata.metadata
        }),
        _reconfigureFundingCyclesData.mustStartAtOrAfter,
        _reconfigureFundingCyclesData.groupedSplits,
        _reconfigureFundingCyclesData.fundAccessConstraints,
        _reconfigureFundingCyclesData.memo
      );
  }
}