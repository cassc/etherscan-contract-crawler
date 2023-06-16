// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ICapitalAgent {
    function addPool(
        address _ssip,
        address _currency,
        uint256 _scr
    ) external;

    function setPolicy(address _policy) external;

    function SSIPWithdraw(uint256 _withdrawAmount) external;

    function SSIPStaking(uint256 _stakingAmount) external;

    function SSIPPolicyCaim(
        uint256 _withdrawAmount,
        uint256 _policyId,
        bool _isFinished
    ) external;

    function checkCapitalByMCR(address _pool, uint256 _withdrawAmount) external view returns (bool);

    function checkCoverageByMLR(uint256 _coverageAmount) external view returns (bool);

    function policySale(uint256 _coverageAmount) external;

    function updatePolicyStatus(uint256 _policyId) external;
}