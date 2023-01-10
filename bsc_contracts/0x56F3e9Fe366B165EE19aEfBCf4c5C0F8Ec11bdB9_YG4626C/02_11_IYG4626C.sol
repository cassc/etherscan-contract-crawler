// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;
import "IERC4626.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IYG4626C is IERC4626 {

    event LogStakingContractUpdated(address stakingContract);
    event LockStatus(bool _status);
    event WhiteList(address _contract, bool _status);
    event Reward(
        address indexed _from,
        address indexed _token,
        uint _value
    );

    function rewardIndex() external view returns (uint256);
    function rewardTS() external view returns (uint256);
    function rewardTS0() external view returns (uint256);
    function rebaseStaker(address) external returns (uint256 iRewardIndex, uint256 cumulativeBalance);    
    function updateRebase() external;
    function lock(address _account, uint256 timestamp) external;
    function rewardOf(address _account) external view returns (uint256);
}