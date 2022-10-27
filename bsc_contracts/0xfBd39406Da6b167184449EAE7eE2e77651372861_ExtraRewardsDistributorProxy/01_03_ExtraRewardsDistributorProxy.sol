// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IExtraRewardsDistributor } from "./Interfaces.sol";
import { IERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

/**
 * @title   ExtraRewardsDistributorProxy
 * @notice  Receives tokens from the Booster as overall reward, then distributes to ExtraRewardsDistributor.
 */
contract ExtraRewardsDistributorProxy {
    address public immutable booster;
    address public immutable extraRewardsDistributor;

    event RewardsDistributed(address indexed token, uint256 amount);

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param _booster                  Booster
     * @param _extraRewardsDistributor  ExtraRewardsDistributor
     */
    constructor(address _booster, address _extraRewardsDistributor) {
        booster = _booster;
        extraRewardsDistributor = _extraRewardsDistributor;
    }

    function queueNewRewards(address _token, uint256 _amount) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        IERC20(_token).approve(extraRewardsDistributor, _amount);
        IExtraRewardsDistributor(extraRewardsDistributor).addReward(_token, _amount);

        emit RewardsDistributed(_token, _amount);
    }
}