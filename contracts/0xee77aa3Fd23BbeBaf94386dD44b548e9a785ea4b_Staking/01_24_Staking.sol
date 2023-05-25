// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Vesting.sol";
import "./LiquidityReserve.sol";
import "../libraries/Ownable.sol";
import "../interfaces/IRewardToken.sol";
import "../interfaces/IVesting.sol";
import "../interfaces/ITokeManager.sol";
import "../interfaces/ITokePool.sol";
import "../interfaces/ITokeReward.sol";
import "../interfaces/ILiquidityReserve.sol";

contract Staking is Ownable {
    using SafeERC20 for IERC20;

    address public immutable TOKE_POOL;
    address public immutable TOKE_MANAGER;
    address public immutable TOKE_REWARD;
    address public immutable STAKING_TOKEN;
    address public immutable REWARD_TOKEN;
    address public immutable TOKE_TOKEN;
    address public immutable LIQUIDITY_RESERVE;
    address public immutable WARM_UP_CONTRACT;
    address public immutable COOL_DOWN_CONTRACT;

    // owner overrides
    bool public pauseStaking = false; // pauses staking
    bool public pauseUnstaking = false; // pauses unstaking

    struct Epoch {
        uint256 length; // length of epoch
        uint256 number; // epoch number (starting 1)
        uint256 endBlock; // block that current epoch ends on
        uint256 distribute; // amount of rewards to distribute this epoch
    }
    Epoch public epoch;

    mapping(address => Claim) public warmUpInfo;
    mapping(address => Claim) public coolDownInfo;

    uint256 public timeLeftToRequestWithdrawal; // time (in seconds) before TOKE cycle ends to request withdrawal
    uint256 public warmUpPeriod; // amount of epochs to delay warmup vesting
    uint256 public coolDownPeriod; // amount of epochs to delay cooldown vesting
    uint256 public requestWithdrawalAmount; // amount of staking tokens to request withdrawal once able to send
    uint256 public withdrawalAmount; // amount of stakings tokens available for withdrawal
    uint256 public lastTokeCycleIndex; // last tokemak cycle index which requested withdrawals

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _tokeToken,
        address _tokePool,
        address _tokeManager,
        address _tokeReward,
        address _liquidityReserve,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochBlock
    ) {
        // must have valid inital addresses
        require(
            _stakingToken != address(0) &&
                _rewardToken != address(0) &&
                _tokeToken != address(0) &&
                _tokePool != address(0) &&
                _tokeManager != address(0) &&
                _tokeReward != address(0) &&
                _liquidityReserve != address(0),
            "Invalid address"
        );
        STAKING_TOKEN = _stakingToken;
        REWARD_TOKEN = _rewardToken;
        TOKE_TOKEN = _tokeToken;
        TOKE_POOL = _tokePool;
        TOKE_MANAGER = _tokeManager;
        TOKE_REWARD = _tokeReward;
        LIQUIDITY_RESERVE = _liquidityReserve;
        timeLeftToRequestWithdrawal = 43200;

        // create vesting contract to hold newly staked rewardTokens based on warmup period
        Vesting warmUp = new Vesting(address(this), REWARD_TOKEN);
        WARM_UP_CONTRACT = address(warmUp);

        // create vesting contract to hold newly unstaked rewardTokens based on cooldown period
        Vesting coolDown = new Vesting(address(this), REWARD_TOKEN);
        COOL_DOWN_CONTRACT = address(coolDown);

        IERC20(STAKING_TOKEN).approve(TOKE_POOL, type(uint256).max);
        IERC20(REWARD_TOKEN).approve(LIQUIDITY_RESERVE, type(uint256).max);

        epoch = Epoch({
            length: _epochLength,
            number: _firstEpochNumber,
            endBlock: _firstEpochBlock,
            distribute: 0
        });
    }

    /**
        @notice claim TOKE rewards from Tokemak
        @dev must get amount through toke reward contract using latest cycle from reward hash contract
        @param _recipient Recipient struct that contains chainId, cycle, address, and amount 
        @param _v uint - recovery id
        @param _r bytes - output of ECDSA signature
        @param _s bytes - output of ECDSA signature
     */
    function claimFromTokemak(
        Recipient calldata _recipient,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // cannot claim 0
        require(_recipient.amount > 0, "Must enter valid amount");

        ITokeReward tokeRewardContract = ITokeReward(TOKE_REWARD);
        tokeRewardContract.claim(_recipient, _v, _r, _s);
    }

    /**
        @notice transfer TOKE from staking contract to address
        @dev used so DAO can get TOKE and manually trade to return FOX to the staking contract
        @param _claimAddress address to send TOKE rewards
     */
    function transferToke(address _claimAddress) external onlyOwner {
        // _claimAddress can't be 0x0
        require(_claimAddress != address(0), "Invalid address");
        uint256 amount = IERC20(TOKE_TOKEN).balanceOf(address(this));
        IERC20(TOKE_TOKEN).safeTransfer(_claimAddress, amount);
    }

    /**
        @notice override whether or not staking is paused
        @dev used to pause staking in case some attack vector becomes present
        @param _shouldPause bool
     */
    function shouldPauseStaking(bool _shouldPause) public onlyOwner {
        pauseStaking = _shouldPause;
    }

    /**
        @notice override whether or not unstaking is paused
        @dev used to pause unstaking in case some attack vector becomes present
        @param _shouldPause bool
     */
    function shouldPauseUnstaking(bool _shouldPause) external onlyOwner {
        pauseUnstaking = _shouldPause;
    }

    /**
        @notice set epoch length
        @dev epoch's determine how long until a rebase can occur
        @param length uint
     */
    function setEpochLength(uint256 length) external onlyOwner {
        epoch.length = length;
    }

    /**
     * @notice set warmup period for new stakers
     * @param _vestingPeriod uint
     */
    function setWarmUpPeriod(uint256 _vestingPeriod) external onlyOwner {
        warmUpPeriod = _vestingPeriod;
    }

    /**
     * @notice set cooldown period for stakers
     * @param _vestingPeriod uint
     */
    function setCoolDownPeriod(uint256 _vestingPeriod) public onlyOwner {
        coolDownPeriod = _vestingPeriod;
    }

    /**
        @notice sets the time before Tokemak cycle ends to requestWithdrawals
        @dev requestWithdrawals is called once per cycle.
        @dev this allows us to change how much time before the end of the cycle we send the withdraw requests
        @param _timestamp uint - time before end of cycle
     */
    function setTimeLeftToRequestWithdrawal(uint256 _timestamp)
        external
        onlyOwner
    {
        timeLeftToRequestWithdrawal = _timestamp;
    }

    /**
        @notice returns true if claim is available
        @dev this shows whether or not our epoch's have passed
        @param _recipient address - warmup address to check if claim is available
        @return bool - true if available to claim
     */
    function _isClaimAvailable(address _recipient)
        internal
        view
        returns (bool)
    {
        Claim memory info = warmUpInfo[_recipient];
        return epoch.number >= info.expiry && info.expiry != 0;
    }

    /**
        @notice returns true if claimWithdraw is available
        @dev this shows whether or not our epoch's have passed as well as if the cycle has increased
        @param _recipient address - address that's checking for available claimWithdraw
        @return bool - true if available to claimWithdraw
     */
    function _isClaimWithdrawAvailable(address _recipient)
        internal
        returns (bool)
    {
        Claim memory info = coolDownInfo[_recipient];
        ITokeManager tokeManager = ITokeManager(TOKE_MANAGER);
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        RequestedWithdrawalInfo memory requestedWithdrawals = tokePoolContract
            .requestedWithdrawals(address(this));
        uint256 currentCycleIndex = tokeManager.getCurrentCycleIndex();
        return
            epoch.number >= info.expiry &&
            info.expiry != 0 &&
            info.amount != 0 &&
            ((requestedWithdrawals.minCycle <= currentCycleIndex &&
                requestedWithdrawals.amount + withdrawalAmount >=
                info.amount) || withdrawalAmount >= info.amount);
    }

    /**
        @notice withdraw stakingTokens from Tokemak
        @dev needs a valid requestWithdrawal inside Tokemak with a completed cycle rollover to withdraw
     */
    function _withdrawFromTokemak() internal {
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        ITokeManager tokeManager = ITokeManager(TOKE_MANAGER);
        RequestedWithdrawalInfo memory requestedWithdrawals = tokePoolContract
            .requestedWithdrawals(address(this));
        uint256 currentCycleIndex = tokeManager.getCurrentCycleIndex();
        if (
            requestedWithdrawals.amount > 0 &&
            requestedWithdrawals.minCycle <= currentCycleIndex
        ) {
            tokePoolContract.withdraw(requestedWithdrawals.amount);
            requestWithdrawalAmount -= requestedWithdrawals.amount;
            withdrawalAmount += requestedWithdrawals.amount;
        }
    }

    /**
        @notice creates a withdrawRequest with Tokemak
        @dev requestedWithdraws take 1 tokemak cycle to be available for withdraw
        @param _amount uint - amount to request withdraw
     */
    function _requestWithdrawalFromTokemak(uint256 _amount) internal {
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        tokePoolContract.requestWithdrawal(_amount);
    }

    /**
        @notice deposit stakingToken to tStakingToken Tokemak reactor
        @param _amount uint - amount to deposit
     */
    function _depositToTokemak(uint256 _amount) internal {
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        tokePoolContract.deposit(_amount);
    }

    /**
        @notice gets balance of stakingToken that's locked into the TOKE stakingToken pool
        @return uint - amount of stakingToken in TOKE pool
     */
    function _getTokemakBalance() internal view returns (uint256) {
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        return tokePoolContract.balanceOf(address(this));
    }

    /**
        @notice checks TOKE's cycleTime is within duration to batch the transactions
        @dev this function returns true if we are within timeLeftToRequestWithdrawal of the end of the TOKE cycle
        @dev as well as if the current cycle index is more than the last cycle index
        @return bool - returns true if can batch transactions
     */
    function _canBatchTransactions() internal view returns (bool) {
        ITokeManager tokeManager = ITokeManager(TOKE_MANAGER);
        uint256 duration = tokeManager.getCycleDuration();
        uint256 currentCycleStart = tokeManager.getCurrentCycle();
        uint256 currentCycleIndex = tokeManager.getCurrentCycleIndex();
        uint256 nextCycleStart = currentCycleStart + duration;

        return
            block.timestamp + timeLeftToRequestWithdrawal >= nextCycleStart &&
            currentCycleIndex > lastTokeCycleIndex &&
            requestWithdrawalAmount > 0;
    }

    /**
        @notice owner function to requestWithdraw all FOX from tokemak in case of an attack on tokemak
        @dev this bypasses the normal flow of sending a withdrawal request and allows the owner to requestWithdraw entire pool balance
     */
    function unstakeAllFromTokemak() public onlyOwner {
        ITokePool tokePoolContract = ITokePool(TOKE_POOL);
        uint256 tokePoolBalance = ITokePool(tokePoolContract).balanceOf(
            address(this)
        );
        // pause any future staking
        shouldPauseStaking(true);
        requestWithdrawalAmount = tokePoolBalance;
        _requestWithdrawalFromTokemak(tokePoolBalance);
    }

    /**
        @notice sends batched requestedWithdrawals due to TOKE's requestWithdrawal overwriting the amount if you call it more than once per cycle
     */
    function sendWithdrawalRequests() public {
        // check to see if near the end of a TOKE cycle
        if (_canBatchTransactions()) {
            // if has withdrawal amount to be claimed then claim
            _withdrawFromTokemak();

            // if more requestWithdrawalAmount exists after _withdrawFromTokemak then request the new amount
            ITokeManager tokeManager = ITokeManager(TOKE_MANAGER);
            if (requestWithdrawalAmount > 0) {
                _requestWithdrawalFromTokemak(requestWithdrawalAmount);
            }

            uint256 currentCycleIndex = tokeManager.getCurrentCycleIndex();
            lastTokeCycleIndex = currentCycleIndex;
        }
    }

    /**
        @notice stake staking tokens to receive reward tokens
        @param _amount uint
        @param _recipient address
     */
    function stake(uint256 _amount, address _recipient) public {
        // if override staking, then don't allow stake
        require(!pauseStaking, "Staking is paused");
        // amount must be non zero
        require(_amount > 0, "Must have valid amount");

        uint256 circulatingSupply = IRewardToken(REWARD_TOKEN)
            .circulatingSupply();

        // Don't rebase unless tokens are already staked or could get locked out of staking
        if (circulatingSupply > 0) {
            rebase();
        }

        IERC20(STAKING_TOKEN).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        Claim storage info = warmUpInfo[_recipient];

        // if claim is available then auto claim tokens
        if (_isClaimAvailable(_recipient)) {
            claim(_recipient);
        }

        _depositToTokemak(_amount);

        // skip adding to warmup contract if period is 0
        if (warmUpPeriod == 0) {
            IERC20(REWARD_TOKEN).safeTransfer(_recipient, _amount);
        } else {
            // create a claim and send tokens to the warmup contract
            warmUpInfo[_recipient] = Claim({
                amount: info.amount + _amount,
                gons: info.gons +
                    IRewardToken(REWARD_TOKEN).gonsForBalance(_amount),
                expiry: epoch.number + warmUpPeriod
            });

            IERC20(REWARD_TOKEN).safeTransfer(WARM_UP_CONTRACT, _amount);
        }
    }

    /**
        @notice call stake with msg.sender
        @param _amount uint
     */
    function stake(uint256 _amount) external {
        stake(_amount, msg.sender);
    }

    /**
        @notice retrieve reward tokens from warmup
        @dev if user has funds in warmup then user is able to claim them (including rewards)
        @param _recipient address
     */
    function claim(address _recipient) public {
        Claim memory info = warmUpInfo[_recipient];
        if (_isClaimAvailable(_recipient)) {
            delete warmUpInfo[_recipient];

            IVesting(WARM_UP_CONTRACT).retrieve(
                _recipient,
                IRewardToken(REWARD_TOKEN).balanceForGons(info.gons)
            );
        }
    }

    /**
        @notice claims staking tokens after cooldown period
        @dev if user has a cooldown claim that's past expiry then withdraw staking tokens from tokemak
        @dev and send them to user
        @param _recipient address - users unstaking address
     */
    function claimWithdraw(address _recipient) public {
        Claim memory info = coolDownInfo[_recipient];
        uint256 totalAmountIncludingRewards = IRewardToken(REWARD_TOKEN)
            .balanceForGons(info.gons);
        if (_isClaimWithdrawAvailable(_recipient)) {
            // if has withdrawalAmount to be claimed, then claim
            _withdrawFromTokemak();

            delete coolDownInfo[_recipient];

            // only give amount from when they requested withdrawal since this amount wasn't used in generating rewards
            // this will later be given to users through addRewardsForStakers
            IERC20(STAKING_TOKEN).safeTransfer(_recipient, info.amount);

            IVesting(COOL_DOWN_CONTRACT).retrieve(
                address(this),
                totalAmountIncludingRewards
            );
            withdrawalAmount -= info.amount;
        }
    }

    /**
        @notice gets reward tokens either from the warmup contract or user's wallet or both
        @dev when transfering reward tokens the user could have their balance still in the warmup contract
        @dev this function abstracts the logic to find the correct amount of tokens to use them
        @param _amount uint
        @param _user address to pull funds from 
     */
    function _retrieveBalanceFromUser(uint256 _amount, address _user) internal {
        Claim memory userWarmInfo = warmUpInfo[_user];
        uint256 walletBalance = IERC20(REWARD_TOKEN).balanceOf(_user);
        uint256 warmUpBalance = IRewardToken(REWARD_TOKEN).balanceForGons(
            userWarmInfo.gons
        );

        // must have enough funds between wallet and warmup
        require(
            _amount <= walletBalance + warmUpBalance,
            "Insufficient Balance"
        );

        uint256 amountLeft = _amount;
        if (warmUpBalance > 0) {
            // remove from warmup first.
            if (_amount >= warmUpBalance) {
                // use the entire warmup balance
                unchecked {
                    amountLeft -= warmUpBalance;
                }

                IVesting(WARM_UP_CONTRACT).retrieve(
                    address(this),
                    warmUpBalance
                );
                delete warmUpInfo[_user];
            } else {
                // partially consume warmup balance
                amountLeft = 0;
                IVesting(WARM_UP_CONTRACT).retrieve(address(this), _amount);
                uint256 remainingGonsAmount = userWarmInfo.gons -
                    IRewardToken(REWARD_TOKEN).gonsForBalance(_amount);
                uint256 remainingAmount = IRewardToken(REWARD_TOKEN)
                    .balanceForGons(remainingGonsAmount);

                warmUpInfo[_user] = Claim({
                    amount: remainingAmount,
                    gons: remainingGonsAmount,
                    expiry: userWarmInfo.expiry
                });
            }
        }

        if (amountLeft != 0) {
            // transfer the rest from the users address
            IERC20(REWARD_TOKEN).safeTransferFrom(
                _user,
                address(this),
                amountLeft
            );
        }
    }

    /**
        @notice redeem reward tokens for staking tokens instantly with fee.  Must use entire amount
        @dev this is in the staking contract due to users having reward tokens (potentially) in the warmup contract
        @dev this function talks to the instantUnstake function in the liquidity reserve contract
        @param _trigger bool - should trigger a rebase
     */
    function instantUnstake(bool _trigger) external {
        // prevent unstaking if override due to vulnerabilities
        require(!pauseUnstaking, "Unstaking is paused");
        if (_trigger) {
            rebase();
        }

        Claim memory userWarmInfo = warmUpInfo[msg.sender];

        uint256 walletBalance = IERC20(REWARD_TOKEN).balanceOf(msg.sender);
        uint256 warmUpBalance = IRewardToken(REWARD_TOKEN).balanceForGons(
            userWarmInfo.gons
        );
        uint256 totalBalance = warmUpBalance + walletBalance;
        uint256 stakingTokenBalance = IERC20(STAKING_TOKEN).balanceOf(
            LIQUIDITY_RESERVE
        );

        // verify that we have enough stakingTokens
        require(totalBalance != 0, "Must have reward tokens");
        require(
            stakingTokenBalance >= totalBalance,
            "Not enough funds in reserve"
        );

        // claim senders warmup balance
        if (warmUpBalance > 0) {
            IVesting(WARM_UP_CONTRACT).retrieve(address(this), warmUpBalance);
            delete warmUpInfo[msg.sender];
        }

        // claim senders wallet balance
        if (walletBalance > 0) {
            IERC20(REWARD_TOKEN).safeTransferFrom(
                msg.sender,
                address(this),
                walletBalance
            );
        }

        // instant unstake from LR contract
        ILiquidityReserve(LIQUIDITY_RESERVE).instantUnstake(
            totalBalance,
            msg.sender
        );
    }

    /**
        @notice redeem reward tokens for staking tokens with a vesting period based on coolDownPeriod
        @dev this function will retrieve the _amount of reward tokens from the user and transfer them to the cooldown contract.
        @dev once the period has expired the user will be able to withdraw their staking tokens
        @param _amount uint - amount of tokens to unstake
        @param _trigger bool - should trigger a rebase
     */
    function unstake(uint256 _amount, bool _trigger) external {
        // prevent unstaking if override due to vulnerabilities asdf
        require(!pauseUnstaking, "Unstaking is paused");
        if (_trigger) {
            rebase();
        }
        _retrieveBalanceFromUser(_amount, msg.sender);

        Claim storage userCoolInfo = coolDownInfo[msg.sender];

        // try to claim withdraw if user has withdraws to claim function will check if withdraw is valid
        claimWithdraw(msg.sender);

        coolDownInfo[msg.sender] = Claim({
            amount: userCoolInfo.amount + _amount,
            gons: userCoolInfo.gons +
                IRewardToken(REWARD_TOKEN).gonsForBalance(_amount),
            expiry: epoch.number + coolDownPeriod
        });

        requestWithdrawalAmount += _amount;

        sendWithdrawalRequests();

        IERC20(REWARD_TOKEN).safeTransfer(COOL_DOWN_CONTRACT, _amount);
    }

    /**
        @notice trigger rebase if epoch has ended
     */
    function rebase() public {
        if (epoch.endBlock <= block.number) {
            IRewardToken(REWARD_TOKEN).rebase(epoch.distribute, epoch.number);

            epoch.endBlock = epoch.endBlock + epoch.length;
            epoch.number++;

            uint256 balance = contractBalance();
            uint256 staked = IRewardToken(REWARD_TOKEN).circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance - staked;
            }
        }
    }

    /**
        @notice returns contract staking tokens holdings 
        @dev gets amount of staking tokens that are a part of this system to calculate rewards
        @dev the staking tokens will be included in this contract plus inside tokemak
        @return uint - amount of staking tokens
     */
    function contractBalance() internal view returns (uint256) {
        uint256 tokeBalance = _getTokemakBalance();
        return IERC20(STAKING_TOKEN).balanceOf(address(this)) + tokeBalance;
    }

    /**
     * @notice adds staking tokens for rebase rewards
     * @dev this is the function that gives rewards so the rebase function can distrubute profits to reward token holders
     * @param _amount uint - amount of tokens to add to rewards
     * @param _trigger bool - should trigger rebase
     */
    function addRewardsForStakers(uint256 _amount, bool _trigger) external {
        IERC20(STAKING_TOKEN).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // deposit all staking tokens held in contract to Tokemak minus tokens waiting for claimWithdraw
        uint256 stakingTokenBalance = IERC20(STAKING_TOKEN).balanceOf(
            address(this)
        );
        uint256 amountToDeposit = stakingTokenBalance - withdrawalAmount;
        _depositToTokemak(amountToDeposit);

        if (_trigger) {
            rebase();
        }
    }
}