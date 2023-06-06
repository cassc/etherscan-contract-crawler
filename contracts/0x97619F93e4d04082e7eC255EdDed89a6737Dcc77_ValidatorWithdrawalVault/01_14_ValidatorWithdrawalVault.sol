// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './library/UtilLib.sol';
import './library/ValidatorStatus.sol';

import './VaultProxy.sol';
import './interfaces/IPenalty.sol';
import './interfaces/IPoolUtils.sol';
import './interfaces/INodeRegistry.sol';
import './interfaces/IStaderStakePoolManager.sol';
import './interfaces/IValidatorWithdrawalVault.sol';
import './interfaces/SDCollateral/ISDCollateral.sol';
import './interfaces/IOperatorRewardsCollector.sol';

import '@openzeppelin/contracts/utils/math/Math.sol';

contract ValidatorWithdrawalVault is IValidatorWithdrawalVault {
    bool internal vaultSettleStatus;
    using Math for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    // Allows the contract to receive ETH
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    function distributeRewards() external override {
        uint8 poolId = VaultProxy(payable(address(this))).poolId();
        uint256 validatorId = VaultProxy(payable(address(this))).id();
        IStaderConfig staderConfig = VaultProxy(payable(address(this))).staderConfig();
        uint256 totalRewards = address(this).balance;
        if (!staderConfig.onlyOperatorRole(msg.sender) && totalRewards > staderConfig.getRewardsThreshold()) {
            emit DistributeRewardFailed(totalRewards, staderConfig.getRewardsThreshold());
            revert InvalidRewardAmount();
        }
        if (totalRewards == 0) {
            revert NotEnoughRewardToDistribute();
        }
        (uint256 userShare, uint256 operatorShare, uint256 protocolShare) = IPoolUtils(staderConfig.getPoolUtils())
            .calculateRewardShare(poolId, totalRewards);

        // Distribute rewards
        IStaderStakePoolManager(staderConfig.getStakePoolManager()).receiveWithdrawVaultUserShare{value: userShare}();
        UtilLib.sendValue(payable(staderConfig.getStaderTreasury()), protocolShare);
        IOperatorRewardsCollector(staderConfig.getOperatorRewardsCollector()).depositFor{value: operatorShare}(
            getOperatorAddress(poolId, validatorId, staderConfig)
        );
        emit DistributedRewards(userShare, operatorShare, protocolShare);
    }

    function settleFunds() external override {
        uint8 poolId = VaultProxy(payable(address(this))).poolId();
        uint256 validatorId = VaultProxy(payable(address(this))).id();
        IStaderConfig staderConfig = VaultProxy(payable(address(this))).staderConfig();
        address nodeRegistry = IPoolUtils(staderConfig.getPoolUtils()).getNodeRegistry(poolId);
        if (msg.sender != nodeRegistry) {
            revert CallerNotNodeRegistryContract();
        }
        (uint256 userSharePrelim, uint256 operatorShare, uint256 protocolShare) = calculateValidatorWithdrawalShare();

        uint256 penaltyAmount = getUpdatedPenaltyAmount(poolId, validatorId, staderConfig);

        if (operatorShare < penaltyAmount) {
            ISDCollateral(staderConfig.getSDCollateral()).slashValidatorSD(validatorId, poolId);
            penaltyAmount = operatorShare;
        }

        uint256 userShare = userSharePrelim + penaltyAmount;
        operatorShare = operatorShare - penaltyAmount;

        // Final settlement
        vaultSettleStatus = true;
        IPenalty(staderConfig.getPenaltyContract()).markValidatorSettled(poolId, validatorId);
        IStaderStakePoolManager(staderConfig.getStakePoolManager()).receiveWithdrawVaultUserShare{value: userShare}();
        UtilLib.sendValue(payable(staderConfig.getStaderTreasury()), protocolShare);
        IOperatorRewardsCollector(staderConfig.getOperatorRewardsCollector()).depositFor{value: operatorShare}(
            getOperatorAddress(poolId, validatorId, staderConfig)
        );
        emit SettledFunds(userShare, operatorShare, protocolShare);
    }

    function calculateValidatorWithdrawalShare()
        public
        view
        returns (
            uint256 _userShare,
            uint256 _operatorShare,
            uint256 _protocolShare
        )
    {
        uint8 poolId = VaultProxy(payable(address(this))).poolId();
        IStaderConfig staderConfig = VaultProxy(payable(address(this))).staderConfig();
        uint256 TOTAL_STAKED_ETH = staderConfig.getStakedEthPerNode();
        uint256 collateralETH = getCollateralETH(poolId, staderConfig); // 0, incase of permissioned NOs
        uint256 usersETH = TOTAL_STAKED_ETH - collateralETH;
        uint256 contractBalance = address(this).balance;

        uint256 totalRewards;

        if (contractBalance <= usersETH) {
            _userShare = contractBalance;
            return (_userShare, _operatorShare, _protocolShare);
        } else if (contractBalance <= TOTAL_STAKED_ETH) {
            _userShare = usersETH;
            _operatorShare = contractBalance - _userShare;
            return (_userShare, _operatorShare, _protocolShare);
        } else {
            totalRewards = contractBalance - TOTAL_STAKED_ETH;
            _operatorShare = collateralETH;
            _userShare = usersETH;
        }
        if (totalRewards > 0) {
            (uint256 userReward, uint256 operatorReward, uint256 protocolReward) = IPoolUtils(
                staderConfig.getPoolUtils()
            ).calculateRewardShare(poolId, totalRewards);
            _userShare += userReward;
            _operatorShare += operatorReward;
            _protocolShare += protocolReward;
        }
    }

    // HELPER METHODS

    function getCollateralETH(uint8 _poolId, IStaderConfig _staderConfig) internal view returns (uint256) {
        return IPoolUtils(_staderConfig.getPoolUtils()).getCollateralETH(_poolId);
    }

    function getOperatorAddress(
        uint8 _poolId,
        uint256 _validatorId,
        IStaderConfig _staderConfig
    ) internal view returns (address) {
        return UtilLib.getOperatorAddressByValidatorId(_poolId, _validatorId, _staderConfig);
    }

    function getUpdatedPenaltyAmount(
        uint8 _poolId,
        uint256 _validatorId,
        IStaderConfig _staderConfig
    ) internal returns (uint256) {
        address nodeRegistry = IPoolUtils(_staderConfig.getPoolUtils()).getNodeRegistry(_poolId);
        (, bytes memory pubkey, , , , , , ) = INodeRegistry(nodeRegistry).validatorRegistry(_validatorId);
        bytes[] memory pubkeyArray = new bytes[](1);
        pubkeyArray[0] = pubkey;
        IPenalty(_staderConfig.getPenaltyContract()).updateTotalPenaltyAmount(pubkeyArray);
        return IPenalty(_staderConfig.getPenaltyContract()).totalPenaltyAmount(pubkey);
    }
}