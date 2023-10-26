// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IStakingContractFeeDetails {
    function getWithdrawerFromPublicKeyRoot(bytes32 _publicKeyRoot) external view returns (address);

    function getTreasury() external view returns (address);

    function getOperatorFeeRecipient(bytes32 pubKeyRoot) external view returns (address);

    function getGlobalFee() external view returns (uint256);

    function getOperatorFee() external view returns (uint256);
}