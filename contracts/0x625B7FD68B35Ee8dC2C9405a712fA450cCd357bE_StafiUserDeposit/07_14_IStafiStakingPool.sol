pragma solidity 0.7.6;
// SPDX-License-Identifier: GPL-3.0-only

import "../../types/DepositType.sol";
import "../../types/StakingPoolStatus.sol";

interface IStafiStakingPool {
    function initialise(address _nodeAddress, DepositType _depositType) external;
    function getStatus() external view returns (StakingPoolStatus);
    function getStatusBlock() external view returns (uint256);
    function getStatusTime() external view returns (uint256);
    function getWithdrawalCredentialsMatch() external view returns (bool);
    function getDepositType() external view returns (DepositType);
    function getNodeAddress() external view returns (address);
    function getNodeFee() external view returns (uint256);
    function getNodeDepositBalance() external view returns (uint256);
    function getNodeRefundBalance() external view returns (uint256);
    function getNodeDepositAssigned() external view returns (bool);
    function getNodeCommonlyRefunded() external view returns (bool);
    function getNodeTrustedRefunded() external view returns (bool);
    function getUserDepositBalance() external view returns (uint256);
    function getUserDepositAssigned() external view returns (bool);
    function getUserDepositAssignedTime() external view returns (uint256);
    function getPlatformDepositBalance() external view returns (uint256);
    function nodeDeposit(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) external payable;
    function userDeposit() external payable;
    function stake(bytes calldata _validatorSignature, bytes32 _depositDataRoot)  external;
    function refund() external;
    function dissolve() external;
    function close() external;
    function voteWithdrawCredentials() external;
}