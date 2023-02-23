// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "@openzeppelin/contracts/governance/TimelockController.sol";
import "./HATGovernanceArbitrator.sol";

contract HATTimelockController is TimelockController {

    constructor(
        uint256 _minDelay,
        address[] memory _proposers,
        address[] memory _executors
    // solhint-disable-next-line no-empty-blocks
    ) TimelockController(_minDelay, _proposers, _executors, address(0)) {}
    
    // The following functions are not subject to the timelock

    function approveClaim(HATGovernanceArbitrator _arbitrator, HATVault _vault, bytes32 _claimId) external onlyRole(PROPOSER_ROLE) {
        _arbitrator.approveClaim(_vault, _claimId);
    }

    function dismissClaim(HATGovernanceArbitrator _arbitrator, HATVault _vault, bytes32 _claimId) external onlyRole(PROPOSER_ROLE) {
        _arbitrator.dismissClaim(_vault, _claimId);
    }

    function setDepositPause(HATVault _vault, bool _depositPause) external onlyRole(PROPOSER_ROLE) {
        _vault.setDepositPause(_depositPause);
    }

    function setVaultVisibility(HATVault _vault, bool _visible) external onlyRole(PROPOSER_ROLE) {
        _vault.registry().setVaultVisibility(address(_vault), _visible);
    }

    function setVaultDescription(HATVault _vault, string memory _descriptionHash) external onlyRole(PROPOSER_ROLE) {
        _vault.setVaultDescription(_descriptionHash);
    }

    function setAllocPoint(HATVault _vault, IRewardController _rewardController, uint256 _allocPoint)
    external onlyRole(PROPOSER_ROLE) {
        _rewardController.setAllocPoint(address(_vault), _allocPoint);
    }

    function setCommittee(HATVault _vault, address _committee) external onlyRole(PROPOSER_ROLE) {
        _vault.setCommittee(_committee);
    }

    function swapAndSend(
        HATVaultsRegistry _registry,
        address _asset,
        address[] calldata _beneficiaries,
        uint256 _amountOutMinimum,
        address _routingContract,
        bytes calldata _routingPayload
    )
    external
    onlyRole(PROPOSER_ROLE) {
        _registry.swapAndSend(
            _asset,
            _beneficiaries,
            _amountOutMinimum,
            _routingContract,
            _routingPayload
        );
    }

    function setEmergencyPaused(HATVaultsRegistry _registry, bool _isEmergencyPaused) external onlyRole(PROPOSER_ROLE) {
        _registry.setEmergencyPaused(_isEmergencyPaused);
    }
}