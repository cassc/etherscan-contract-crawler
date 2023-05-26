// SPDX-License-Identifier: MIT
//                                                      *****+=:.  .=*****+-.      -#@@#-.   .+*****=:.     .****+:   :*****+=:.   -***:  -+**=   =***.
//                ...:=*#%%#*=:..       .+%@*.          @@@@%@@@@* .#@@@%%@@@*.  [email protected]@@@%@@@-  :%@@@%%@@@-    [email protected]@@@@#   [email protected]@@@%@@@@+  [email protected]@@-   #@@@:  %@@%
//             .:=%@@@@@@@@@@@@@@#-.  .#@@@@%:          @@@% .#@@%=.#@@*  [email protected]@@= -%@@#: #@@@: :%@@- [email protected]@@@   [email protected]@@#@@#   [email protected]@@* :%@@*: [email protected]@@-   [email protected]@@+ [email protected]@@.
//           .-%@@@@@@%%%%%%%%@@@@@@+=%@@@%*.           @@@%  :@@@*.#@@*  [email protected]@@= [email protected]@@-  *@@@- :%@@=..%@@@   [email protected]@%[email protected]@%:  [email protected]@@* [email protected]@#: [email protected]@@-    *@@@:%@@+
//          -%@@@@%##=.      :*##@@@@@@@%#.             @@@@:-*@@%=.#@@#::*@@%- [email protected]@@-  [email protected]@@= :%@@*+#@@@=   [email protected]@%[email protected]@@#  [email protected]@@#+#@@@=  [email protected]@@-    .#@@[email protected]@%
//        [email protected]@@@#*:              *@@@@@#-               @@@@@@@@#+ .#@@@@@@@@=  [email protected]@@-  [email protected]@@+.:%@@%##@@#:   @@@#.%@@#  [email protected]@@%#%@@#-. [email protected]@@-     [email protected]@@@@:
//       :*@@@@+.              .=%@@@#*.                @@@@***+.  .#@@%+*%@@#: [email protected]@@-  *@@@+ :%@@-  %@@@. [email protected]@@#=*@@%- [email protected]@@* :*@@@= [email protected]@@-      #@@@#
//      .#@@@%=              .-#@@@%#:    :             @@@%       .#@@*  [email protected]@@= [email protected]@@=  *@@@- :%@@-  [email protected]@@= [email protected]@@@@@@@@* [email protected]@@*  [email protected]@@= [email protected]@@-      *@@@:
//      [email protected]@@@=              :*@@@@#-.   .-%:            @@@%       .#@@*  [email protected]@@= -%@@*=-%@@#. :%@@*=-%@@@: @@@@++*@@@# [email protected]@@#--*@@%- [email protected]@@*----. *@@@:
//     [email protected]@@@+             :=#@@@#+:    [email protected]@*.           @@@%       .#@@*  [email protected]@@=  -#@@@@@@#:  :%@@@@@@@*+ [email protected]@@#  .*@@%[email protected]@@@@@@@#-  [email protected]@@@@@@@: *@@@:
//     [email protected]@@%            .-#@@@%*:      *@@@@.           +++=       .=++-  :+++:   :++++++.   .++++++++.  :+++:   :+++-.+++++++=:   -++++++++. -+++.
//     #@@@%           :*@@@@#-.       -%@@@.
//     %@@@%         :+#@@@#=:         :%@@@.                             .                                                        .
//     [email protected]@@%       .=#@@@@*:           [email protected]@@@.           ++++=  :++=   :++***++: .=+++++++++. =++=  .+++-  +++=  .+++=. :+++-   :++***++:
//     :@@@%-     :*@@@@#-.            *@@@%.           @@@@%  [email protected]@#  :#@@@#%@@#:-%@@@@@@@@@: %@@%. :@@@*  @@@%  :@@@@+ [email protected]@@+  :#@@%#@@@#:
//      @@@@#   .*#@@@#=:             =%@@@=            @@@@@= [email protected]@# [email protected]@@+:=%@@*:---#@@@+--. %@@%. :@@@*  @@@%  :@@@@#:[email protected]@@+ :%@@*::*@@@-
//      [email protected]@@@+ =#@@@@*:              -%@@@#.            @@@#@% [email protected]@# :%@@*. [email protected]@%-   *@@@-    %@@%. :@@@*  @@@%  :@@@@@[email protected]@@+ [email protected]@@=  :---.
//       [email protected]@@@#%@@@#-.              =%@@@@-             @@@[email protected]@*[email protected]@# [email protected]@@*   [email protected]@@=   *@@@-    %@@@#*#@@@*  @@@%  :@@%[email protected]%*@@@+ [email protected]@@= -****:
//        [email protected]@@@@@%=.              :*@@@@%-              @@@-%@%[email protected]@# [email protected]@@*   [email protected]@@=   *@@@-    %@@@@@@@@@*  @@@%  :@@#[email protected]@%@@@+ [email protected]@@= [email protected]@@@-
//        [email protected]@@@@*.              -#%@@@@+:               @@@=:@@%@@# [email protected]@@*   [email protected]@@=   *@@@-    %@@%-:[email protected]@@*  @@@%  :@@#[email protected]@@@@+ [email protected]@@= .*@@@-
//      .%@@@@%:.    :*+-:-=*#%%@@@@@%-                 @@@=.#@@@@# .*@@%- :#@@#:   *@@@-    %@@%. :@@@*  @@@%  :@@# [email protected]@@@@+ [email protected]@@=  [email protected]@@-
//     *%@@@@=.    :#%@@@%@@@@@@@@@*:.                  @@@= :@@@@#  [email protected]@@%+#@@@+    *@@@-    %@@%. :@@@*  @@@%  :@@#  [email protected]@@@+ .*@@@*+%@@@- -#%%:
//   :%@@@@#.     .#@@@@@@@@@@@@*:.                     @@@= .#@@@#   [email protected]@@@@@@+     *@@@-    %@@%. :@@@*  @@@%  :@@#  [email protected]@@@+  -%@@@@@@@@- :%@@:
//    .:-:.         ....:::.....                        ..     ...     ..:::..       ...      ..    ...   ...    ..    ....     .::.....    ..
//
/// @title Probably Nothing Staking Rewards
/// @author 0xEwok and audie.eth
/// @notice Auto-compounding staking rewards for PRBLY.

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakedProbablyNothing is Ownable, ERC20Burnable {
   event AddStake(address indexed _addr, uint _baseTokenValue, uint _stakedTokenValue);
   event RemoveStake(address indexed _addr, uint _baseTokenValue, uint _stakedTokenValue);
   event FundRewards(address indexed _addr, uint _numEpochs, uint _secondsPerEpoch, uint _rewardsPerEpoch);

    // token address to be staked
    address private tokenAddress;
    // amount of token staked
    uint256 private poolDeposits;
    // token rewards to be vested per epoch
    uint256 private rewardsPerEpoch;
    // tracker variable to track amount funded
    uint256 private cumulativeFundedRewards;

    // cumulative rewards withdrawn
    uint256 private poolWithdrawals;
    uint private rewardsPeriodStartTime;
    uint private rewardsPeriodEndTime;
    uint private rewardsFundedEpochs;
    // vesting interval length
    uint private rewardsEpochLength = 86400;

    constructor(
        string memory name_,
        string memory symbol_,
        address tokenAddress_
    ) ERC20(name_, symbol_) {
        tokenAddress = tokenAddress_;
    }

    /** @notice Mints staked token. Also referred to as "staking token".
     */
    function _mint(address account, uint256 amount) internal override (ERC20) {
        super._mint(account, amount);
    }

    /** @notice Setup and fund the staking rewards period
     *  @param rewardsPerEpoch_ the base token rewards per epoch
     *  @param numEpochs_ the number of epochs to fund
     *  @param secondsPerEpoch_ the number of seconds per epoch
     */
    function fundStakingRewards(uint numEpochs_, uint secondsPerEpoch_, uint256 rewardsPerEpoch_) public onlyOwner {
        // validate input parameters
        require(secondsPerEpoch_ > 0, "Sanity check: minimum epoch length is 1 second");
        require(secondsPerEpoch_ < 86401, "Sanity check: can only set epoch length up to 1 day");
        require(numEpochs_ * secondsPerEpoch_ < 15552000, "Sanity check: can only setup 180 days of rewards at a time");

        // update tracking variables before transfer
        // must be done if at least one withdrawal or vested rewards > 0, so just do every time
        // ok to do if only deposits, or if nothing happened yet
        // check invariants: can only be called when another staking period is not active
        require(block.timestamp > rewardsPeriodEndTime, "Invariant check: Can only update rewards after prior rewards period ends");
        require(block.timestamp > rewardsPeriodStartTime, "Re-entry check: Cannot update rewards before rewards period starts");

        poolDeposits = getStakingPoolSize();
        poolWithdrawals = 0;

        // transfer token in
        uint rewardsTotal = rewardsPerEpoch_ * numEpochs_;
        require(
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), rewardsTotal),
            "Failed transferring tokens from sender"
        );

        // set tracking variables for this vesting rewards period
        rewardsEpochLength = secondsPerEpoch_;
        rewardsPerEpoch = rewardsPerEpoch_;
        rewardsFundedEpochs = numEpochs_;
        rewardsPeriodStartTime = block.timestamp;
        rewardsPeriodEndTime = block.timestamp + numEpochs_ * rewardsEpochLength;
        require(vestedRewards() == 0, "Invariant failed: vested rewards should be 0. None should have vested yet.");

        // read-only variable to track cumulative rewards
        cumulativeFundedRewards = cumulativeFundedRewards + rewardsTotal;

        emit FundRewards(msg.sender, numEpochs_, secondsPerEpoch_, rewardsPerEpoch_);
    }

    /** @notice The length of a vesting period in seconds
     */
    function getRewardsEpochLength() public view returns (uint256) {
        return rewardsEpochLength;
    }

    /** @notice The start time for this reward period
     */
    function getRewardsPeriodStartTime() public view returns (uint256) {
        return rewardsPeriodStartTime;
    }

    /** @notice The end time for this reward period
     */
    function getRewardsPeriodEndTime() public view returns (uint256) {
        return rewardsPeriodEndTime;
    }

    /** @notice Base token rewards per epoch, shared equally across staking token holders
     */
    function getRewardsPerEpoch() public view returns (uint256) {
        return rewardsPerEpoch;
    }

    /** @notice The number of epochs with funded rewards
     */
    function getRewardsFundedEpochs() public view returns (uint256) {
        return rewardsFundedEpochs;
    }

    /** @notice The total base tokens deposited for this reward period
     */
    function getPoolDeposits() public view returns (uint256) {
        return poolDeposits;
    }

    /** @notice The total base tokens withdrawn for this reward period
     */
    function getRewardsPeriodPoolWithdrawalsTotal() public view returns (uint256) {
        return poolWithdrawals;
    }

    /** @notice The total funded rewards for this reward period
     */
    function totalRewards() public view returns (uint256) {
        return rewardsPerEpoch * rewardsFundedEpochs;
    }

    /** @notice The number of elapsed epochs that have vested for this reward period
     */
    function getElapsedEpochs() public view returns (uint256) {
        if (rewardsPeriodStartTime == 0) {
            return 0;
        }
        if (block.timestamp >= rewardsPeriodEndTime) {
            return rewardsFundedEpochs;
        }
        return (block.timestamp - rewardsPeriodStartTime) / rewardsEpochLength;
    }

    /** @notice The remaining number of epochs that will vest for this reward period
     */
    function getRemainingEpochs() public view returns (uint256) {
        return rewardsFundedEpochs - getElapsedEpochs();
    }

    /** @notice The amount of rewards that have vested for this reward period
     */
    function vestedRewards() public view returns (uint256) {
        if (rewardsPeriodStartTime == 0 || block.timestamp < rewardsPeriodStartTime) {
            return 0;
        }

        uint elapsedEpochs = (block.timestamp - rewardsPeriodStartTime) / rewardsEpochLength;
        if (elapsedEpochs >= rewardsFundedEpochs) {
            return totalRewards();
        }

        return elapsedEpochs * rewardsPerEpoch;
    }

    /** @notice The next vest time
     */
    function nextVestTime() public view returns (uint256) {
        if (rewardsPeriodStartTime == 0 || block.timestamp < rewardsPeriodStartTime) {
            return 0;
        }

        uint elapsedEpochs = (block.timestamp - rewardsPeriodStartTime) / rewardsEpochLength;
        if (elapsedEpochs >= rewardsFundedEpochs) {
            return rewardsPeriodStartTime + rewardsFundedEpochs * rewardsEpochLength;
        }

        return rewardsPeriodStartTime + (elapsedEpochs + 1) * rewardsEpochLength;
    }

    /** @notice The number of seconds until the next vest time
     */
    function secondsUntilNextVest() public view returns (uint256) {
        return nextVestTime() - block.timestamp;
    }

    /** @notice Whether rewards are actively vesting
     */
    function isVestingRewardsNow() public view returns (bool) {
        return block.timestamp >= rewardsPeriodStartTime && block.timestamp < rewardsPeriodEndTime;
    }

    /** @notice The size of the staking pool, including deposits and vested rewards
     */
    function getStakingPoolSize() public view returns (uint256) {
        return poolDeposits + vestedRewards() - poolWithdrawals;
    }

    /** @notice Convert base token to staking token based on current conversion ratio
     *  @param amount The amount of based token
     */
    function toStakedToken(uint256 amount) public view returns (uint256) {
        uint256 totalStakedToken = totalSupply();

        // first staker has claim to entire pool, even if some of it has vested already
        if (totalStakedToken == 0) {
            return amount;
        }

        uint256 totalBaseToken = getStakingPoolSize();

        // ammount * staking/base
        return amount * totalStakedToken / totalBaseToken;
    }

    /** @notice Convert staking token to base token based on current conversion ratio
     *  @param amount The amount of staking token
     */
    function toBaseToken(uint256 amount) public view returns (uint256) {
        uint256 totalStakedToken = totalSupply();

        if (totalStakedToken == 0) {
            return amount;
        }

        uint256 totalBaseToken = getStakingPoolSize();

        // ammount * base/staking
        return amount * totalBaseToken / totalStakedToken;
    }

    /** @notice Stake base token and received staked token.
     */
    function addStake(uint256 baseTokenAmount) external {
        // take base token token in
        require(
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), baseTokenAmount),
            "Failed transferring token from sender"
        );

        // conversion relies on supply of staked token and amount of base token staked, so must do math first
        uint256 stakedTokenAmount = toStakedToken(baseTokenAmount);

        // give back staked token
        _mint(msg.sender, stakedTokenAmount);
        poolDeposits += baseTokenAmount;

        emit AddStake(msg.sender, baseTokenAmount, stakedTokenAmount);
    }

    /** @notice Remove staking token and withdraw base token.
     */
    function removeStake(uint256 stakedTokenAmount) external {
        // take staking token in
        require(
            stakedTokenAmount <= balanceOf(msg.sender), "Cannot remove stake for more tokens than owned"
        );

        // give back their stake
        uint256 baseTokenAmount = toBaseToken(stakedTokenAmount);
        require(baseTokenAmount <= getStakingPoolSize(), "Converted token amount is greater than staked + rewards. Something went wrong.");
        require(
            IERC20(tokenAddress).transfer(msg.sender, baseTokenAmount),
            "Insufficient token reward in staking contract. Unexpected."
        );

        // burn their staked token
        burn(stakedTokenAmount);
        poolWithdrawals += baseTokenAmount;

        emit RemoveStake(msg.sender, baseTokenAmount, stakedTokenAmount);
    }

    /** @notice The cumulative amount of rewards that have been funded.
     */
    function getCumulativeFundedRewards() public view returns (uint256) {
        return cumulativeFundedRewards;
    }

    /** @notice The cumulative amount of rewards that have vested.
     */
    function getCumulativeVestedRewards() public view returns (uint256) {
        return cumulativeFundedRewards + vestedRewards() - totalRewards();
    }
}