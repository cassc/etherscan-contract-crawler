// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IDegradable {

    event SetPolicyParameters(
        address indexed admin, 
        uint32 indexed policyId, 
        uint256 degradationPeriod, 
        uint256 degradationFreshness);

    struct MitigationParameters {
        uint256 degradationPeriod;
        uint256 degradationFreshness;
    }

    function ROLE_SERVICE_SUPERVISOR() external view returns (bytes32);

    function defaultDegradationPeriod() external view returns (uint256);

    function defaultFreshnessPeriod() external view returns (uint256);

    function policyManager() external view returns (address);

    function lastUpdate() external view returns (uint256);

    function subjectUpdates(bytes32 subject) external view returns (uint256 timestamp);

    function setPolicyParameters(
        uint32 policyId,
        uint256 degradationPeriod,
        uint256 degradationFreshness
    ) external;

    function canMitigate(
        address observer, 
        bytes32 subject, 
        uint32 policyId
    ) external view returns (bool canIndeed) ;

    function isDegraded(uint32 policyId) external view returns (bool isIndeed);

    function isMitigationQualified(
        bytes32 subject,
        uint32 policyId
    ) external view returns (bool qualifies);

    function degradationPeriod(uint32 policyId) external view returns (uint256 inSeconds);

    function degradationFreshness(uint32 policyId) external view returns (uint256 inSeconds);

    function mitigationCutoff(uint32 policyId) external view returns (uint256 cutoffTime);
}