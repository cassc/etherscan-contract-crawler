pragma solidity 0.8.8;

/**
 * @title Interface for LargeStaking
 * @notice Vault factory
 */

import {CLStakingExitInfo, CLStakingSlashInfo} from "src/library/ConsensusStruct.sol";

interface ILargeStaking {
    event SharedRewardPoolStart(uint256 _operatorId, address _elRewardPoolAddr);
    event LargeStake(
        uint256 _operatorId,
        uint256 _curStakingId,
        uint256 _amount,
        address _owner,
        address _elRewardAddr,
        address _withdrawCredentials,
        bool _isELRewardSharing
    );
    event MigretaStake(
        uint256 _operatorId,
        uint256 _curStakingId,
        uint256 _amount,
        address _owner,
        address _elRewardAddr,
        address _withdrawCredentials,
        bool _isELRewardSharing
    );
    event AppendStake(uint256 _stakingId, uint256 _amount);
    event AppendMigretaStake(uint256 _stakingId, uint256 _stakeAmounts);
    event ValidatorRegistered(uint256 _operatorId, uint256 _stakeingId, bytes _pubKey);
    event FastUnstake(uint256 _stakingId, uint256 _unstakeAmount);
    event LargeUnstake(uint256 _stakingId, uint256 _amount);
    event ELShareingRewardSettle(uint256 _operatorId, uint256 _daoReward, uint256 _operatorReward, uint256 _poolReward);
    event ElPrivateRewardSettle(
        uint256 _stakingId, uint256 _operatorId, uint256 _daoReward, uint256 _operatorReward, uint256 _poolReward
    );
    event UserRewardClaimed(uint256 _stakingId, address _beneficiary, uint256 _rewards);
    event OperatorRewardClaimed(uint256 _operatorId, address _rewardAddresses, uint256 _rewardAmounts);
    event OperatorPrivateRewardClaimed(uint256 _stakingId, uint256 _operatorId, uint256 _operatorRewards);
    event OperatorSharedRewardClaimed(uint256 _operatorId, uint256 _operatorRewards);
    event DaoPrivateRewardClaimed(uint256 _stakingId, address _daoVaultAddress, uint256 _daoRewards);
    event DaoSharedRewardClaimed(uint256 _operatorId, address daoVaultAddress, uint256 _daoRewards);
    event LargeStakingSlash(uint256 _stakingIds, uint256 _operatorIds, bytes _pubkey, uint256 _amounts);
    event ValidatorExitReport(uint256 _operatorId, bytes _pubkey);
    event DaoAddressChanged(address _oldDao, address _dao);
    event DaoVaultAddressChanged(address _oldDaoVaultAddress, address _daoVaultAddress);
    event DaoELCommissionRateChanged(uint256 _oldDaoElCommissionRate, uint256 _daoElCommissionRate);
    event NodeOperatorsRegistryChanged(address _oldNodeOperatorRegistryContract, address _nodeOperatorRegistryAddress);
    event ConsensusOracleChanged(address _oldLargeOracleContractAddr, address _largeOracleContractAddr);
    event ELRewardFactoryChanged(address _oldElRewardFactory, address _elRewardFactory);
    event OperatorSlashChanged(address _oldOperatorSlashContract, address _operatorSlashContract);
    event MinStakeAmountChanged(uint256 _oldMinStakeAmount, uint256 _minStakeAmount);
    event MaxSlashAmountChanged(uint256 _oldMaxSlashAmount, uint256 _maxSlashAmount);
    event ElRewardAddressChanged(address _oldElRewardAddr, address _elRewardAddr);

    function getOperatorValidatorCounts(uint256 _operatorId) external view returns (uint256);

    function reportCLStakingData(
        CLStakingExitInfo[] memory _clStakingExitInfo,
        CLStakingSlashInfo[] memory _clStakingSlashInfo
    ) external;
}