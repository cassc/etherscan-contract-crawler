// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IExemptionsManager {
   
    event ExemptionsManagerInitialized(address indexed admin, address indexed policyManager);

    event AdmitGlobalExemption(address indexed admin, address indexed exemption, string description);

    event UpdateGlobalExemption(address indexed admin, address indexed exemption, string description);

    event ApprovePolicyExemptions(address indexed admin, uint32 policyId, address indexed exemption);

    function ROLE_GLOBAL_EXEMPTIONS_ADMIN() external view returns (bytes32);

    function policyManager() external view returns (address);

    function exemptionDescriptions(address) external view returns (string memory);

    function init(address policyManager_) external;

    function admitGlobalExemption(address[] calldata exemptAddresses, string memory description) external;

    function updateGlobalExemption(address exemptAddress, string memory description) external;

    function approvePolicyExemptions(uint32 policyId, address[] memory exemptions) external;

    function globalExemptionsCount() external view returns (uint256 count);

    function globalExemptionAtIndex(uint256 index) external view returns (address exemption);

    function isGlobalExemption(address exemption) external view returns (bool isIndeed);

    function policyExemptionsCount(uint32 policyId) external view returns (uint256 count);

    function policyExemptionAtIndex(uint32 policyId, uint256 index) external view returns (address exemption);

    function isPolicyExemption(uint32 policyId, address exemption) external view returns (bool isIndeed);

}