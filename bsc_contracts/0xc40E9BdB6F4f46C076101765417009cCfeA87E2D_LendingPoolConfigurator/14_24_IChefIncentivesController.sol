// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IOnwardIncentivesController.sol";

interface IChefIncentivesController {

  struct PoolInfo {
      uint256 totalSupply;
      uint256 allocPoint; // How many allocation points assigned to this pool.
      uint256 lastRewardTime; // Last second that reward distribution occurs.
      uint256 accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
      IOnwardIncentivesController onwardIncentives;
  }

  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param user The address of the user
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   **/
  function handleAction(
    address user,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

    function addPool(address _token, uint256 _allocPoint) external;

    function claim(address _user, address[] calldata _tokens) external;

    function setClaimReceiver(address _user, address _receiver) external;

    function claimableReward(address _user, address[] calldata _tokens)
      external
      view
      returns (uint256[] memory);

}