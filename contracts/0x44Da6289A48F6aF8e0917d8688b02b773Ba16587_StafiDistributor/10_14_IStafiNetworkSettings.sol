pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNetworkSettings {
    function getNodeConsensusThreshold() external view returns (uint256);
    function getSubmitBalancesEnabled() external view returns (bool);
    function getProcessWithdrawalsEnabled() external view returns (bool);
    function getNodeFee() external view returns (uint256);
    function getPlatformFee() external view returns (uint256);
    function getNodeRefundRatio() external view returns (uint256);
    function getNodeTrustedRefundRatio() external view returns (uint256);
    function getWithdrawalCredentials() external view returns (bytes memory);
    function getSuperNodePubkeyLimit() external view returns (uint256);
}