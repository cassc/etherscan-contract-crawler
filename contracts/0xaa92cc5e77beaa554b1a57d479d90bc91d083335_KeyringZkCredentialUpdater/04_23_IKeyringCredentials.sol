// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IKeyringCredentials {
    
    event CredentialsDeployed(
        address deployer, 
        address trustedForwarder, 
        address policyManager, 
        uint256 maximumConsentPeriod);

    event CredentialsInitialized(address admin);

    event UpdateCredential(
        uint8 version, 
        address updater, 
        address indexed trader, 
        uint32 indexed admissionPolicyId);

    function ROLE_CREDENTIAL_UPDATER() external view returns (bytes32);

    function init() external;

    function setCredential(
        address trader,  
        uint32 admissionPolicyId,
        uint256 timestamp
    ) external;

    function checkCredential(
        address observer,
        address subject,
        uint32 admissionPolicyId
    ) external returns (bool passed);

    function keyGen(
        address trader,
        uint32 admissionPolicyId
    ) external pure returns (bytes32 key);

}