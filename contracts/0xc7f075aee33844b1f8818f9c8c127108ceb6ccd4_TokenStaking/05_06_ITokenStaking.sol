// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev Interface of the TokenStaking.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 *
 * Note: Deployer will be the {owner}.
 */
interface ITokenStaking {
    /**
     * @dev User custom datatype.
     *
     * `amount` - How many tokens user has provided.
     * `rewardPaid` - How much reward is paid to user.
     * `lastUpdated` - When did he staked his amount.
     */
    struct UserInfo {
        uint256 amount;
        uint256 rewardPaid;
        uint256 lastUpdated;
    }

    /**
     * @dev Action type enum.
     */
    enum ActionType {
        Stake,
        Unstake
    }

    /**
     * @dev Emitted when some ether is received from fallback.
     */
    event RecieveTriggered(address user, uint256 amount);

    /**
     * @dev Emitted when a `user` stakes `amount` tokens.
     */
    event Staked(address indexed user, uint256 amount, uint256 stakeNum);

    /**
     * @dev Emitted when a `user` unstakes `amount` tokens and `reward`.
     */
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 reward,
        uint256 stakeNum
    );

    /**
     * @dev Emitted when a {owner} withdraws funds.
     */
    event OwnerWithdrawFunds(address indexed beneficiary, uint256 amount);

    /**
     * @dev Emitted when a {apy} is changed.
     */
    event APYChanged(uint256 apy);

    /**
     * @dev Returns the total value locked in contract.
     */
    function totalValueLocked() external view returns (uint256);

    /**
     * @dev Returns the {apy} value.
     */
    function apy() external view returns (uint256);

    /**
     * @dev Returns the values of {UserInfo}.
     */
    function userInfos(address, uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev Returns the number of stakes of an address.
     */
    function stakeNums(address) external view returns (uint256);

    /**
     * @dev Returns the staked balance of a `_account` having corresponding `_stakeNum`.
     */
    function balanceOf(address _account, uint256 _stakeNum)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a boolean value if stake exists of a `_beneficiary` with `_stakeNum`.
     */
    function stakeExists(address _beneficiary, uint256 _stakeNum)
        external
        view
        returns (bool);

    /**
     * @dev Returns the reward amount of a `_beneficiary` with `_stakeNum`.
     */
    function calculateReward(address _beneficiary, uint256 _stakeNum)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total token balance of this contract.
     */
    function contractTokenBalance() external view returns (uint256);

    /**
     * @dev Stakes `_amount` amount of tokens in this contract.
     *
     * Emits a {Staked} event.
     */
    function stake(uint256 _amount) external;

    /**
     * @dev Unstakes the stake having `_stakeNum`.
     *
     * Emits a {Unstaked} event.
     */
    function unstake(uint256 _stakeNum) external;

    /**
     * @dev Sets {apy} to `_apy`.
     *
     * Note that caller must be {owner}.
     *
     * Emits a {APYChanged} event.
     */
    function changeAPY(uint256 _apy) external;

    /**
     * @dev Allows {owner} to withdraw all funds from this contract.
     *
     * Note that caller must be {owner}.
     *
     * Emits a {OwnerWithdrawFunds} event.
     */
    function withdrawContractFunds(uint256 _amount) external;

    /**
     * @dev Destructs this contract and transfers all funds to {owner}.
     *
     * Note that caller must be {owner}.
     *
     */
    function destructContract() external;
}