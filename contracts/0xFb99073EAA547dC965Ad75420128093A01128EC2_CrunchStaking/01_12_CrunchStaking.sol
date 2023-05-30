// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./erc677/IERC677Receiver.sol";
import "./access/HasCrunchParent.sol";
import "./CrunchToken.sol";

/**
 * DataCrunch Staking contract for the CRUNCH token.
 *
 * To start staking, use the {CrunchStaking-deposit(address)} method, but this require an allowance from your account.
 * Another method is to do a {CrunchToken-transferAndCall(address, uint256, bytes)} to avoid doing 2 transactions. (as per ERC-677 standart)
 *
 * Withdrawing will withdraw everything. There is currently no method to only withdraw a specific amount.
 *
 * @author Enzo CACERES
 * @author Arnaud CASTILLO
 */
contract CrunchStaking is HasCrunchParent, IERC677Receiver {
    event Withdrawed(
        address indexed to,
        uint256 reward,
        uint256 staked,
        uint256 totalAmount
    );

    event EmergencyWithdrawed(address indexed to, uint256 staked);
    event Deposited(address indexed sender, uint256 amount);
    event RewardPerDayUpdated(uint256 rewardPerDay, uint256 totalDebt);

    struct Holder {
        /** Index in `addresses`, used for faster lookup in case of a remove. */
        uint256 index;
        /** When does an holder stake for the first time (set to `block.timestamp`). */
        uint256 start;
        /** Total amount staked by the holder. */
        uint256 totalStaked;
        /** When the reward per day is updated, the reward debt is updated to ensure that the previous reward they could have got isn't lost. */
        uint256 rewardDebt;
        /** Individual stakes. */
        Stake[] stakes;
    }

    struct Stake {
        /** How much the stake is. */
        uint256 amount;
        /** When does the stakes 'start' is. When created it is `block.timestamp`, and is updated when the `reward per day` is updated. */
        uint256 start;
    }

    /** The `reward per day` is the amount of tokens rewarded for 1 million CRUNCHs staked over a 1 day period. */
    uint256 public rewardPerDay;

    /** List of all currently staking addresses. Used for looping. */
    address[] public addresses;

    /** address to Holder mapping. */
    mapping(address => Holder) public holders;

    /** Currently total staked amount by everyone. It is incremented when someone deposit token, and decremented when someone withdraw. This value does not include the rewards. */
    uint256 public totalStaked;

    /** @dev Initializes the contract by specifying the parent `crunch` and the initial `rewardPerDay`. */
    constructor(CrunchToken crunch, uint256 _rewardPerDay)
        HasCrunchParent(crunch)
    {
        rewardPerDay = _rewardPerDay;
    }

    /**
     * @dev Deposit an `amount` of tokens from your account to this contract.
     *
     * This will start the staking with the provided amount.
     * The implementation call {IERC20-transferFrom}, so the caller must have previously {IERC20-approve} the `amount`.
     *
     * Emits a {Deposited} event.
     *
     * Requirements:
     * - `amount` cannot be the zero address.
     * - `caller` must have a balance of at least `amount`.
     *
     * @param amount amount to reposit.
     */
    function deposit(uint256 amount) external {
        crunch.transferFrom(_msgSender(), address(this), amount);

        _deposit(_msgSender(), amount);
    }

    /**
     * Withdraw the staked tokens with the reward.
     *
     * Emits a {Withdrawed} event.
     *
     * Requirements:
     * - `caller` to be staking.
     */
    function withdraw() external {
        _withdraw(_msgSender());
    }

    /**
     * Returns the current reserve for rewards.
     *
     * @return the contract balance - the total staked.
     */
    function reserve() public view returns (uint256) {
        uint256 balance = contractBalance();

        if (totalStaked > balance) {
            revert(
                "Staking: the balance has less CRUNCH than the total staked"
            );
        }

        return balance - totalStaked;
    }

    /**
     * Test if the caller is currently staking.
     *
     * @return `true` if the caller is staking, else if not.
     */
    function isCallerStaking() external view returns (bool) {
        return isStaking(_msgSender());
    }

    /**
     * Test if an address is currently staking.
     *
     * @param `addr` address to test.
     * @return `true` if the address is staking, else if not.
     */
    function isStaking(address addr) public view returns (bool) {
        return _isStaking(holders[addr]);
    }

    /**
     * Get the current balance in CRUNCH of this smart contract.
     *
     * @return The current staking contract's balance in CRUNCH.
     */
    function contractBalance() public view returns (uint256) {
        return crunch.balanceOf(address(this));
    }

    /**
     * Returns the sum of the specified `addr` staked amount.
     *
     * @param addr address to check.
     * @return the total staked of the holder.
     */
    function totalStakedOf(address addr) external view returns (uint256) {
        return holders[addr].totalStaked;
    }

    /**
     * Returns the computed reward of everyone.
     *
     * @return total the computed total reward of everyone.
     */
    function totalReward() public view returns (uint256 total) {
        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];

            total += totalRewardOf(addr);
        }
    }

    /**
     * Compute the reward of the specified `addr`.
     *
     * @param addr address to test.
     * @return the reward the address would get.
     */
    function totalRewardOf(address addr) public view returns (uint256) {
        Holder storage holder = holders[addr];

        return _computeRewardOf(holder);
    }

    /**
     * Sum the reward debt of everyone.
     *
     * @return total the sum of all `Holder.rewardDebt`.
     */
    function totalRewardDebt() external view returns (uint256 total) {
        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];

            total += rewardDebtOf(addr);
        }
    }

    /**
     * Get the reward debt of an holder.
     *
     * @param addr holder's address.
     * @return the reward debt of the holder.
     */
    function rewardDebtOf(address addr) public view returns (uint256) {
        return holders[addr].rewardDebt;
    }

    /**
     * Test if the reserve is sufficient to cover the `{totalReward()}`.
     *
     * @return whether the reserve has enough CRUNCH to give to everyone.
     */
    function isReserveSufficient() external view returns (bool) {
        return _isReserveSufficient(totalReward());
    }

    /**
     * Test if the reserve is sufficient to cover the `{totalRewardOf(address)}` of the specified address.
     *
     * @param addr address to test.
     * @return whether the reserve has enough CRUNCH to give to this address.
     */
    function isReserveSufficientFor(address addr) external view returns (bool) {
        return _isReserveSufficient(totalRewardOf(addr));
    }

    /**
     * Get the number of address current staking.
     *
     * @return the length of the `addresses` array.
     */
    function stakerCount() external view returns (uint256) {
        return addresses.length;
    }

    /**
     * Get the stakes array of an holder.
     *
     * @param addr address to get the stakes array.
     * @return the holder's stakes array.
     */
    function stakesOf(address addr) external view returns (Stake[] memory) {
        return holders[addr].stakes;
    }

    /**
     * Get the stakes array length of an holder.
     *
     * @param addr address to get the stakes array length.
     * @return the length of the `stakes` array.
     */
    function stakesCountOf(address addr) external view returns (uint256) {
        return holders[addr].stakes.length;
    }

    /**
     * @dev ONLY FOR EMERGENCY!!
     *
     * Force an address to withdraw.
     *
     * @dev Should only be called if a {CrunchStaking-destroy()} would cost too much gas to be executed.
     *
     * @param addr address to withdraw.
     */
    function forceWithdraw(address addr) external onlyOwner {
        _withdraw(addr);
    }

    /**
     * @dev ONLY FOR EMERGENCY!!
     *
     * Emergency withdraw.
     *
     * All rewards are discarded. Only initial staked amount will be transfered back!
     *
     * Emits a {EmergencyWithdrawed} event.
     *
     * Requirements:
     * - `caller` to be staking.
     */
    function emergencyWithdraw() external {
        _emergencyWithdraw(_msgSender());
    }

    /**
     * @dev ONLY FOR EMERGENCY!!
     *
     * Force an address to emergency withdraw.
     *
     * @dev Should only be called if a {CrunchStaking-emergencyDestroy()} would cost too much gas to be executed.
     *
     * @param addr address to emergency withdraw.
     */
    function forceEmergencyWithdraw(address addr) external onlyOwner {
        _emergencyWithdraw(addr);
    }

    /**
     * Update the reward per day.
     *
     * This will recompute a reward debt with the previous reward per day value.
     * The debt is used to make sure that everyone will keep their rewarded tokens using the previous reward per day value for the calculation.
     *
     * Emits a {RewardPerDayUpdated} event.
     *
     * Requirements:
     * - `to` must not be the same as the reward per day.
     * - `to` must be below or equal to 15000.
     *
     * @param to new reward per day value.
     */
    function setRewardPerDay(uint256 to) external onlyOwner {
        require(
            rewardPerDay != to,
            "Staking: reward per day value must be different"
        );
        require(
            to <= 15000,
            "Staking: reward per day must be below 15000/1M token/day"
        );

        uint256 debt = _updateDebts();
        rewardPerDay = to;

        emit RewardPerDayUpdated(rewardPerDay, debt);
    }

    /**
     * @dev ONLY FOR EMERGENCY!!
     *
     * Empty the reserve if there is a problem.
     */
    function emptyReserve() external onlyOwner {
        uint256 amount = reserve();

        require(amount != 0, "Staking: reserve is empty");

        crunch.transfer(owner(), amount);
    }

    /**
     * Destroy the contact after withdrawing everyone.
     *
     * @dev If the reserve is not zero after the withdraw, the remaining will be sent back to the contract's owner.
     */
    function destroy() external onlyOwner {
        uint256 usable = reserve();

        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];
            Holder storage holder = holders[addr];

            uint256 reward = _computeRewardOf(holder);

            require(usable >= reward, "Staking: reserve does not have enough");

            uint256 total = holder.totalStaked + reward;
            crunch.transfer(addr, total);
        }

        _transferRemainingAndSelfDestruct();
    }

    /**
     * @dev ONLY FOR EMERGENCY!!
     *
     * Destroy the contact after emergency withdrawing everyone, avoiding the reward computation to save gas.
     *
     * If the reserve is not zero after the withdraw, the remaining will be sent back to the contract's owner.
     */
    function emergencyDestroy() external onlyOwner {
        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];
            Holder storage holder = holders[addr];

            crunch.transfer(addr, holder.totalStaked);
        }

        _transferRemainingAndSelfDestruct();
    }

    /**
     * @dev ONLY FOR CRITICAL EMERGENCY!!
     *
     * Destroy the contact without withdrawing anyone.
     * Only use this function if the code has a fatal bug and its not possible to do otherwise.
     */
    function criticalDestroy() external onlyOwner {
        _transferRemainingAndSelfDestruct();
    }

    /** @dev Internal function called when the {IERC677-transferAndCall} is used. */
    function onTokenTransfer(
        address sender,
        uint256 value,
        bytes memory data
    ) external override onlyCrunchParent {
        data; /* silence unused */

        _deposit(sender, value);
    }

    /**
     * Deposit.
     *
     * @dev If the depositor is not currently holding, the `Holder.start` is set and his address is added to the addresses list.
     *
     * @param from depositor address.
     * @param amount amount to deposit.
     */
    function _deposit(address from, uint256 amount) internal {
        require(amount != 0, "cannot deposit zero");

        Holder storage holder = holders[from];

        if (!_isStaking(holder)) {
            holder.start = block.timestamp;
            holder.index = addresses.length;
            addresses.push(from);
        }

        holder.totalStaked += amount;
        holder.stakes.push(Stake({amount: amount, start: block.timestamp}));

        totalStaked += amount;

        emit Deposited(from, amount);
    }

    /**
     * Withdraw.
     *
     * @dev This will remove the `Holder` from the `holders` mapping and the address from the `addresses` array.
     *
     * Requirements:
     * - `addr` must be staking.
     * - the reserve must have enough token.
     *
     * @param addr address to withdraw.
     */
    function _withdraw(address addr) internal {
        Holder storage holder = holders[addr];

        require(_isStaking(holder), "Staking: no stakes");

        uint256 reward = _computeRewardOf(holder);

        require(
            _isReserveSufficient(reward),
            "Staking: the reserve does not have enough token"
        );

        uint256 staked = holder.totalStaked;
        uint256 total = staked + reward;
        crunch.transfer(addr, total);

        totalStaked -= staked;

        _deleteAddress(holder.index);
        delete holders[addr];

        emit Withdrawed(addr, reward, staked, total);
    }

    /**
     * Emergency withdraw.
     *
     * This is basically the same as {CrunchStaking-_withdraw(address)}, but without the reward.
     * This function must only be used for emergencies as it consume less gas and does not have the check for the reserve.
     *
     * @dev This will remove the `Holder` from the `holders` mapping and the address from the `addresses` array.
     *
     * Requirements:
     * - `addr` must be staking.
     *
     * @param addr address to withdraw.
     */
    function _emergencyWithdraw(address addr) internal {
        Holder storage holder = holders[addr];

        require(_isStaking(holder), "Staking: no stakes");

        uint256 staked = holder.totalStaked;
        crunch.transfer(addr, staked);

        totalStaked -= staked;

        _deleteAddress(holder.index);
        delete holders[addr];

        emit EmergencyWithdrawed(addr, staked);
    }

    /**
     * Test if the `reserve` is sufficiant for a specified reward.
     *
     * @param reward value to test.
     * @return if the reserve is bigger or equal to the `reward` parameter.
     */
    function _isReserveSufficient(uint256 reward) private view returns (bool) {
        return reserve() >= reward;
    }

    /**
     * Test if an holder struct is currently staking.
     *
     * @dev Its done by testing if the stake array length is equal to zero. Since its not possible, it mean that the holder is not currently staking and the struct is only zero.
     *
     * @param holder holder struct.
     * @return `true` if the holder is staking, `false` otherwise.
     */
    function _isStaking(Holder storage holder) internal view returns (bool) {
        return holder.stakes.length != 0;
    }

    /**
     * Update the reward debt of all holders.
     *
     * @dev Usually called before a `reward per day` update.
     *
     * @return total total debt updated.
     */
    function _updateDebts() internal returns (uint256 total) {
        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];
            Holder storage holder = holders[addr];

            uint256 debt = _updateDebtsOf(holder);

            holder.rewardDebt += debt;

            total += debt;
        }
    }

    /**
     * Update the reward debt of a specified `holder`.
     *
     * @param holder holder struct to update.
     * @return total sum of debt added.
     */
    function _updateDebtsOf(Holder storage holder)
        internal
        returns (uint256 total)
    {
        uint256 length = holder.stakes.length;
        for (uint256 index = 0; index < length; index++) {
            Stake storage stake = holder.stakes[index];

            total += _computeStakeReward(stake);

            stake.start = block.timestamp;
        }
    }

    /**
     * Compute the reward for every holder.
     *
     * @return total the total of all of the reward for all of the holders.
     */
    function _computeTotalReward() internal view returns (uint256 total) {
        uint256 length = addresses.length;
        for (uint256 index = 0; index < length; index++) {
            address addr = addresses[index];
            Holder storage holder = holders[addr];

            total += _computeRewardOf(holder);
        }
    }

    /**
     * Compute all stakes reward for an holder.
     *
     * @param holder the holder struct.
     * @return total total reward for the holder (including the debt).
     */
    function _computeRewardOf(Holder storage holder)
        internal
        view
        returns (uint256 total)
    {
        uint256 length = holder.stakes.length;
        for (uint256 index = 0; index < length; index++) {
            Stake storage stake = holder.stakes[index];

            total += _computeStakeReward(stake);
        }

        total += holder.rewardDebt;
    }

    /**
     * Compute the reward of a single stake.
     *
     * @param stake the stake struct.
     * @return the token rewarded (does not include the debt).
     */
    function _computeStakeReward(Stake storage stake)
        internal
        view
        returns (uint256)
    {
        uint256 numberOfDays = ((block.timestamp - stake.start) / 1 days);

        return (stake.amount * numberOfDays * rewardPerDay) / 1_000_000;
    }

    /**
     * Delete an address from the `addresses` array.
     *
     * @dev To avoid holes, the last value will replace the deleted address.
     *
     * @param index address's index to delete.
     */
    function _deleteAddress(uint256 index) internal {
        uint256 length = addresses.length;
        require(
            length != 0,
            "Staking: cannot remove address if array length is zero"
        );

        uint256 last = length - 1;
        if (last != index) {
            address addr = addresses[last];
            addresses[index] = addr;
            holders[addr].index = index;
        }

        addresses.pop();
    }

    /**
     * Transfer the remaining tokens back to the current contract owner and then self destruct.
     *
     * @dev This function must only be called for destruction!!
     * @dev If the balance is 0, the `CrunchToken#transfer(address, uint256)` is not called.
     */
    function _transferRemainingAndSelfDestruct() internal {
        uint256 remaining = contractBalance();
        if (remaining != 0) {
            crunch.transfer(owner(), remaining);
        }

        selfdestruct(payable(owner()));
    }
}