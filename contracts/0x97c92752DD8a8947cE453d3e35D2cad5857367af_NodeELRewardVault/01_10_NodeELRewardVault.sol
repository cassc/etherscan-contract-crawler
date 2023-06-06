// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './library/UtilLib.sol';

import './interfaces/IPoolUtils.sol';
import './interfaces/IVaultProxy.sol';
import './interfaces/INodeRegistry.sol';
import './interfaces/INodeELRewardVault.sol';
import './interfaces/IStaderStakePoolManager.sol';
import './interfaces/IOperatorRewardsCollector.sol';

contract NodeELRewardVault is INodeELRewardVault {
    constructor() {}

    /**
     * @notice Allows the contract to receive ETH
     * @dev execution layer rewards may be sent as plain ETH transfers
     */
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    function withdraw() external override {
        uint8 poolId = IVaultProxy(address(this)).poolId();
        uint256 operatorId = IVaultProxy(address(this)).id();
        IStaderConfig staderConfig = IVaultProxy(address(this)).staderConfig();
        uint256 totalRewards = address(this).balance;
        if (totalRewards == 0) {
            revert NotEnoughRewardToWithdraw();
        }
        (uint256 userShare, uint256 operatorShare, uint256 protocolShare) = IPoolUtils(staderConfig.getPoolUtils())
            .calculateRewardShare(poolId, totalRewards);

        // Distribute rewards
        IStaderStakePoolManager(staderConfig.getStakePoolManager()).receiveExecutionLayerRewards{value: userShare}();
        // slither-disable-next-line arbitrary-send-eth
        UtilLib.sendValue(payable(staderConfig.getStaderTreasury()), protocolShare);
        address operator = UtilLib.getOperatorAddressByOperatorId(poolId, operatorId, staderConfig);
        IOperatorRewardsCollector(staderConfig.getOperatorRewardsCollector()).depositFor{value: operatorShare}(
            operator
        );

        emit Withdrawal(protocolShare, operatorShare, userShare);
    }
}