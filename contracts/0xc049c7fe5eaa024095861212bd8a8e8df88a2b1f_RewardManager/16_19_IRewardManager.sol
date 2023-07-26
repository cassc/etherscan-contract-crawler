// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

// interfaces
import "./IRewardManagerL2.sol";
import "./IStaking.sol";

interface IRewardManager is IRewardManagerL2 {
    /**
     * @notice used to get the staking contract address
     * @return staking contract address (or Staking contract type in Solidity)
     */
    function staking() external view returns (IStaking);
}