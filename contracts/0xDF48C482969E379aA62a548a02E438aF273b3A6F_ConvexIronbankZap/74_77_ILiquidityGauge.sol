// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice the liquidity gauge, i.e. staking contract, for the stablecoin pool
 */
interface ILiquidityGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    /**
     * @notice Claim available reward tokens for msg.sender
     */
    // solhint-disable-next-line func-name-mixedcase
    function claim_rewards() external;

    /**
     * @notice Get the number of claimable reward tokens for a user
     * @dev This function should be manually changed to "view" in the ABI
     *      Calling it via a transaction will claim available reward tokens
     * @param _addr Account to get reward amount for
     * @param _token Token to get reward amount for
     * @return uint256 Claimable reward token amount
     */
    // solhint-disable-next-line func-name-mixedcase
    function claimable_reward(address _addr, address _token)
        external
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}