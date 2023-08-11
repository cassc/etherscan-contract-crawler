// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IIdentityTree {

    event Deployed(
        address admin, 
        address trustedForwarder_, 
        address policyManager_, 
        uint256 maximumConsentPeriod);
    
    event SetMerkleRootBirthday(bytes32 merkleRoot, uint256 birthday);

    struct PolicyMitigation {
        uint256 mitigationFreshness;
        uint256 degradationPeriod;
    }

    function ROLE_AGGREGATOR() external view returns (bytes32);
   
    function setMerkleRootBirthday(bytes32 root, uint256 birthday) external;

    function checkRoot(
        address observer, 
        bytes32 merkleRoot,
        uint32 admissionPolicyId
    ) external returns (bool passed);

    function merkleRootCount() external view returns (uint256 count);

    function merkleRootAtIndex(uint256 index) external view returns (bytes32 merkleRoot);

    function isMerkleRoot(bytes32 merkleRoot) external view returns (bool isIndeed);

    function latestRoot() external view returns (bytes32 root);
}