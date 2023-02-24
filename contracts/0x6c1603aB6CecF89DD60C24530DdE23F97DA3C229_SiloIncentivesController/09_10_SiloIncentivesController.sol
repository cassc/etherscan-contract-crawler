// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseIncentivesController} from "../external/aave/incentives/base/BaseIncentivesController.sol";
import "../interfaces/INotificationReceiver.sol";


/**
 * @title SiloIncentivesController
 * @notice Distributor contract for rewards to the Aave protocol, using a staked token as rewards asset.
 * The contract stakes the rewards before redistributing them to the Aave protocol participants.
 * The reference staked token implementation is at https://github.com/aave/aave-stake-v2
 * @author Aave
 */
contract SiloIncentivesController is BaseIncentivesController, INotificationReceiver {
    using SafeERC20 for IERC20;

    constructor(IERC20 rewardToken, address emissionManager) BaseIncentivesController(rewardToken, emissionManager) {}

    /**
     * @dev Silo share token event handler
     */
    function onAfterTransfer(address /* _token */, address _from, address _to, uint256 _amount) external {
        if (assets[msg.sender].lastUpdateTimestamp == 0) {
            // optimisation check, if we never configured rewards distribution, then no need for updating any data
            return;
        }

        uint256 totalSupplyBefore = IERC20(msg.sender).totalSupply();

        if (_from == address(0x0)) {
            // we minting tokens, so supply before was less
            // we safe, because this amount came from token, if token handle them we can handle as well
            unchecked { totalSupplyBefore -= _amount; }
        } else if (_to == address(0x0)) {
            // we burning, so supply before was more
            // we safe, because this amount came from token, if token handle them we can handle as well
            unchecked { totalSupplyBefore += _amount; }
        }

        // here user either transferring token to someone else or burning tokens
        // user state will be new, because this event is `onAfterTransfer`
        // we need to recreate status before event in order to automatically calculate rewards
        if (_from != address(0x0)) {
            uint256 balanceBefore;
            // we safe, because this amount came from token, if token handle them we can handle as well
            unchecked { balanceBefore = IERC20(msg.sender).balanceOf(_from) + _amount; }
            handleAction(_from, totalSupplyBefore, balanceBefore);
        }

        // we have to checkout also user `_to`
        if (_to != address(0x0)) {
            uint256 balanceBefore;
            // we safe, because this amount came from token, if token handle them we can handle as well
            unchecked { balanceBefore = IERC20(msg.sender).balanceOf(_to) - _amount; }
            handleAction(_to, totalSupplyBefore, balanceBefore);
        }
    }

    /// @dev it will transfer all balance of reward token to emission manager wallet
    function rescueRewards() external onlyEmissionManager {
        IERC20(REWARD_TOKEN).safeTransfer(msg.sender, IERC20(REWARD_TOKEN).balanceOf(address(this)));
    }

    function notificationReceiverPing() external pure returns (bytes4) {
        return this.notificationReceiverPing.selector;
    }

    function _transferRewards(address to, uint256 amount) internal override {
        IERC20(REWARD_TOKEN).safeTransfer(to, amount);
    }

    /**
     * @dev in Silo, there is no scale, we simply using balance and total supply. Original method name is used here
     * to keep as much of original code.
     */
    function _getScaledUserBalanceAndSupply(address _asset, address _user)
        internal
        virtual
        view
        override
        returns (uint256 userBalance, uint256 totalSupply)
    {
        userBalance = IERC20(_asset).balanceOf(_user);
        totalSupply = IERC20(_asset).totalSupply();
    }
}