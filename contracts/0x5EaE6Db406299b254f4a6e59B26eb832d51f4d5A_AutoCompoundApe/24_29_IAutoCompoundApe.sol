// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "../dependencies/openzeppelin/contracts/IERC20.sol";

interface IAutoCompoundApe is IERC20 {
    /**
     * @dev Emitted during deposit()
     * @param user The address of the user deposit for
     * @param amountDeposited The amount being deposit
     * @param amountShare The share being deposit
     **/
    event Deposit(
        address indexed caller,
        address indexed user,
        uint256 amountDeposited,
        uint256 amountShare
    );

    /**
     * @dev Emitted during withdraw()
     * @param user The address of the user
     * @param amountWithdraw The amount being withdraw
     * @param amountShare The share being withdraw
     **/
    event Redeem(
        address indexed user,
        uint256 amountWithdraw,
        uint256 amountShare
    );

    /**
     * @dev Emitted during rescueERC20()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being rescued
     **/
    event RescueERC20(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @notice deposit an `amount` of ape into compound pool.
     * @param onBehalf The address of user will receive the pool share
     * @param amount The amount of ape to be deposit
     **/
    function deposit(address onBehalf, uint256 amount) external;

    /**
     * @notice withdraw an `amount` of ape from compound pool.
     * @param amount The amount of ape to be withdraw
     **/
    function withdraw(uint256 amount) external;

    /**
     * @notice collect ape reward in ApeCoinStaking and deposit to earn compound interest.
     **/
    function harvestAndCompound() external;
}