// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

import "./base/MultipleRewardPool.sol";
import "./interfaces/ILunchBox.sol";
import "./interfaces/ISnacksBase.sol";

contract SnacksPool is MultipleRewardPool {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;
    using PRBMathUD60x18 for uint256;

    address public lunchBox;
    address public snacks;
    address public btcSnacks;
    address public ethSnacks;
    uint256 private _excludedHoldersSupply;
    uint256 private _notExcludedHoldersSupply;
    uint256 private _excludedHoldersLunchBoxSupply;
    uint256 private _notExcludedHoldersLunchBoxSupply;
    uint256 private _totalSupplyFactor = PRBMathUD60x18.fromUint(1);
    Counters.Counter private _currentTotalSupplyFactorId;

    mapping(address => mapping(uint256 => bool)) private _adjusted;
    mapping(address => uint256) public lastActivationTimePerUser;
    EnumerableSet.AddressSet private _lunchBoxParticipants;
    
    event RewardsDelivered(
        uint256 indexed totalRewardAmountForParticipantsInSnacks_,
        uint256 indexed totalRewardAmountForParticipantsInBtcSnacks,
        uint256 indexed totalRewardAmountForParticipantsInEthSnacks,
        uint256 zoinksBusdAmountOutMin_,
        uint256 btcBusdAmountOutMin_,
        uint256 ethBusdAmountOutMin_
    );
    event TotalSupplyFactorUpdated(
        uint256 indexed totalSupplyFactor, 
        uint256 indexed totalSupplyFactorId
    );

    modifier onlySnacks {
        require(
            msg.sender == snacks,
            "SnacksPool: caller is not the Snacks contract"
        );
        _;
    }

    /**
    * @param snacks_ Snacks token address.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    * @param seniorage_ Seniorage contract address.
    * @param rewardTokens_ Reward token addresses.
    */
    constructor(
        address snacks_,
        address poolRewardDistributor_,
        address seniorage_,
        address[] memory rewardTokens_
    )
        MultipleRewardPool(
            snacks_,
            poolRewardDistributor_,
            seniorage_,
            rewardTokens_
        )
    {}
    
    /**
    * @notice Configures the contract.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param lunchBox_ LunchBox contract address.
    * @param snacks_ Snacks token address.
    * @param btcSnacks_ BtcSnacks token address.
    * @param ethSnacks_ EthSnacks token address.
    * @param authority_ Authorised address.
    */
    function configure(
        address lunchBox_,
        address snacks_,
        address btcSnacks_,
        address ethSnacks_,
        address authority_
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lunchBox = lunchBox_;
        snacks = snacks_;
        btcSnacks = btcSnacks_;
        ethSnacks = ethSnacks_;
        _grantRole(AUTHORITY_ROLE, authority_);
        if (IERC20(snacks_).allowance(address(this), lunchBox_) == 0) {
            IERC20(snacks_).approve(lunchBox_, type(uint256).max);
        }
        if (IERC20(btcSnacks_).allowance(address(this), lunchBox_) == 0) {
            IERC20(btcSnacks_).approve(lunchBox_, type(uint256).max);
        }
        if (IERC20(ethSnacks_).allowance(address(this), lunchBox_) == 0) {
            IERC20(ethSnacks_).approve(lunchBox_, type(uint256).max);
        }
    }

    /**
    * @notice Updates total supply factor and increments its id.
    * @dev Adjusts `rewardPerTokenStored` and `userRewardPerTokenPaid` to the correct values 
    * after increasing the deposits of non-excluded holders.
    * @param totalSupplyBefore_ Total supply before new adjustment factor value in the Snacks contract.
    */
    function updateTotalSupplyFactor(uint256 totalSupplyBefore_) external onlySnacks {
        if (totalSupplyBefore_ != 0) {
            uint256 totalSupply = getTotalSupply();
            _totalSupplyFactor = totalSupply.div(totalSupplyBefore_);
            for (uint256 i = 0; i < _rewardTokens.length(); i++) {
                address rewardToken = _rewardTokens.at(i);
                rewardPerTokenStored[rewardToken] = rewardPerTokenStored[rewardToken].div(_totalSupplyFactor);
            }
            _currentTotalSupplyFactorId.increment();
            emit TotalSupplyFactorUpdated(
                _totalSupplyFactor,
                _currentTotalSupplyFactorId.current()
            );
        }
    }
    
    /**
    * @notice Activates the risk-free investment program for the user.
    * @dev Activation is possible only if the user's deposit is not 0.
    * After activation, all user rewards will be deposited into the LunchBox contract.
    */
    function activateLunchBox() external whenNotPaused {
        require(
            _balances[msg.sender] > 0,
            "SnacksPool: only active stakers are able to activate LunchBox"
        );
        getReward();
        ILunchBox(lunchBox).updateRewardForUser(msg.sender);
        require(
            _lunchBoxParticipants.add(msg.sender),
            "SnacksPool: already activated"
        );
        lastActivationTimePerUser[msg.sender] = block.timestamp;
        if (ISnacksBase(snacks).isExcludedHolder(msg.sender)) {
            _excludedHoldersLunchBoxSupply += _balances[msg.sender];
        } else {
            _notExcludedHoldersLunchBoxSupply += _balances[msg.sender];
        }
    }

    /**
    * @notice Deposits tokens for the user.
    * @dev Updates user's last deposit time. The deposit amount of tokens cannot be equal to 0.
    * @param amount_ Amount of tokens to deposit.
    */
    function stake(
        uint256 amount_
    ) 
        external 
        override
        whenNotPaused
        nonReentrant 
        updateReward(msg.sender) 
    {
        if (ISnacksBase(snacks).isExcludedHolder(msg.sender)) {
            require(
                amount_ > 0,
                "SnacksPool: can not stake 0"
            );
            if (_lunchBoxParticipants.contains(msg.sender)) {
                ILunchBox(lunchBox).updateRewardForUser(msg.sender);
                _excludedHoldersLunchBoxSupply += amount_;
            }
            _balances[msg.sender] += amount_;
            _excludedHoldersSupply += amount_;
        } else {
            uint256 adjustedAmount = amount_.div(ISnacksBase(snacks).adjustmentFactor());
            require(
                adjustedAmount > 0,
                "SnacksPool: invalid amount to stake"
            );
            if (_lunchBoxParticipants.contains(msg.sender)) {
                ILunchBox(lunchBox).updateRewardForUser(msg.sender);
                _notExcludedHoldersLunchBoxSupply += adjustedAmount;
            }
            _balances[msg.sender] += adjustedAmount;
            _notExcludedHoldersSupply += adjustedAmount;
        }
        userLastDepositTime[msg.sender] = block.timestamp;
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount_);
        emit Staked(msg.sender, amount_);
    }

    /**
    * @notice Notifies the contract of an incoming reward in one of the reward tokens 
    * and recalculates the reward rate.
    * @dev Called by the PoolRewardDistributor contract once every 12 hours.
    * @param rewardToken_ Address of one of the reward tokens.
    * @param reward_ Reward amount.
    */
    function notifyRewardAmount(
        address rewardToken_,
        uint256 reward_
    )
        external
        override
        onlyPoolRewardDistributor
        onlyValidToken(rewardToken_)
        updateRewardPerToken(rewardToken_, address(0))
    {
        if (block.timestamp >= periodFinishPerToken[rewardToken_]) {
            rewardRates[rewardToken_] = reward_ / rewardsDuration;
        } else {
            uint256 remaining = periodFinishPerToken[rewardToken_] - block.timestamp;
            uint256 leftover = remaining * rewardRates[rewardToken_];
            rewardRates[rewardToken_] = (reward_ + leftover) / rewardsDuration;
        }
        uint256 balance;
        if (rewardToken_ == snacks) {
            balance = IERC20(rewardToken_).balanceOf(address(this)) - getTotalSupply();
        } else {
            balance = IERC20(rewardToken_).balanceOf(address(this));
        }
        require(
            rewardRates[rewardToken_] <= balance / rewardsDuration,
            "SnacksPool: provided reward too high"
        );
        lastUpdateTimePerToken[rewardToken_] = block.timestamp;
        periodFinishPerToken[rewardToken_] = block.timestamp + rewardsDuration;
        emit RewardAdded(rewardToken_, reward_);
    }

    /** 
    * @notice Delivers all the accumulated rewards in 
    * Snacks/BtcSnacks/EthSnacks token to the LunchBox holders.
    * @dev Called by the authorised address once every 12 hours.
    * @param totalRewardAmountForParticipantsInSnacks_ Total amount of Snacks token that 
    * belongs to the LunchBox participants.
    * @param totalRewardAmountForParticipantsInBtcSnacks_ Total amount of BtcSnacks token that 
    * belongs to the LunchBox participants.
    * @param totalRewardAmountForParticipantsInEthSnacks_ Total amount of EthSnacks token that 
    * belongs to the LunchBox participants.
    * @param zoinksBusdAmountOutMin_ The amount of slippage tolerance for 
    * Zoinks token to Binance-Peg BUSD token swap.
    * @param btcBusdAmountOutMin_ The amount of slippage tolerance for 
    * Binance-Peg BTCB token to Binance-Peg BUSD token swap.
    * @param ethBusdAmountOutMin_ The amount of slippage tolerance for 
    * Binance-Peg Ethereum token to Binance-Peg BUSD token swap.
    */
    function deliverRewardsForAllLunchBoxParticipants(
        uint256 totalRewardAmountForParticipantsInSnacks_,
        uint256 totalRewardAmountForParticipantsInBtcSnacks_,
        uint256 totalRewardAmountForParticipantsInEthSnacks_,
        uint256 zoinksBusdAmountOutMin_,
        uint256 btcBusdAmountOutMin_,
        uint256 ethBusdAmountOutMin_
    ) 
        external 
        whenNotPaused
        onlyRole(AUTHORITY_ROLE)
    {
        ILunchBox(lunchBox).stakeForSnacksPool(
            totalRewardAmountForParticipantsInSnacks_,
            totalRewardAmountForParticipantsInBtcSnacks_,
            totalRewardAmountForParticipantsInEthSnacks_,
            zoinksBusdAmountOutMin_,
            btcBusdAmountOutMin_,
            ethBusdAmountOutMin_
        );
        emit RewardsDelivered(
            totalRewardAmountForParticipantsInSnacks_,
            totalRewardAmountForParticipantsInBtcSnacks_,
            totalRewardAmountForParticipantsInEthSnacks_,
            zoinksBusdAmountOutMin_,
            btcBusdAmountOutMin_,
            ethBusdAmountOutMin_
        );
    }
    
    /** 
    * @notice Checks whether the user is a participant of the risk-free investment program.
    * @dev If the user is a participant of the risk-free investment program, 
    * then the reward pattern for him becomes different.
    * @param user_ User address.
    * @return Boolean value indicating whether the user is a paricipant of the risk-free investment program.
    */
    function isLunchBoxParticipant(address user_) external view returns (bool) {
        return _lunchBoxParticipants.contains(user_);
    }

    /** 
    * @notice Returns the amount of risk-free investment program participants.
    * @dev The time complexity of this function is derived from EnumerableSet.Bytes32Set set so it's
    * able to be used in some small count iteration operations.
    * @return The exact amount of the participants.
    */
    function getLunchBoxParticipantsLength() external view returns (uint256) {
        return _lunchBoxParticipants.length();
    }

    /** 
    * @notice Returns an address of specific participant of risk-free investment program.
    * @dev The time complexity of this function is derived from EnumerableSet.Bytes32Set set so it's
    * able to be used freely in any internal operations (like DELEGATECALL use cases).
    * @return The address of a participant.
    */
    function getLunchBoxParticipantAt(uint256 index_) external view returns (address) {
        return _lunchBoxParticipants.at(index_);
    }

    /** 
    * @notice Returns the amount of supply that belong to risk-free investment program.
    * @dev Mind that the `_notExcludedHoldersLunchBoxSupply` variable is 
    * adjusted by factor of Snacks contract.
    * @return The exact amount of the supply.
    */
    function getLunchBoxParticipantsTotalSupply() external view returns (uint256) {
        return 
            _notExcludedHoldersLunchBoxSupply.mul(ISnacksBase(snacks).adjustmentFactor())
            + _excludedHoldersLunchBoxSupply;
    }

    /** 
    * @notice Returns the amount of supply that belongs to not excluded holders.
    * @dev Mind that the `_notExcludedHoldersSupply` variable is 
    * adjusted by factor of Snacks contract.
    * @return The exact amount of the not excluded holders supply.
    */
    function getNotExcludedHoldersSupply() external view returns (uint256) {
        return _notExcludedHoldersSupply.mul(ISnacksBase(snacks).adjustmentFactor());
    }

    /**
    * @notice Retrieves the potential reward amount in one
    * of the reward tokens for duration.
    * @dev Reward rate may change, so this function is not completely accurate.
    * @param rewardToken_ Address of one of the reward tokens.
    * @param user_ User address.
    * @param duration_ Arbitrary time interval in seconds.
    * @return Potential reward amount in one of the reward tokens for given duration.
    */
    function calculatePotentialReward(
        address rewardToken_,
        address user_,
        uint256 duration_
    )
        external
        view
        override
        onlyValidToken(rewardToken_)
        returns (uint256)
    {
        uint256 rewardPerTokenPaid = userRewardPerTokenPaid[rewardToken_][user_];
        if (!_adjusted[user_][_currentTotalSupplyFactorId.current()]) {
            rewardPerTokenPaid = rewardPerTokenPaid.div(_totalSupplyFactor);
        }
        return
            getBalance(user_)
            * (_rewardPerTokenForDuration(rewardToken_, duration_) - rewardPerTokenPaid)
            / 1e18
            + rewards[user_][rewardToken_];
    }

    /**
    * @notice Deactivates the risk-free investment program for the user.
    * @dev Deactivation is possible only if 24 hours have passed 
    * since the last activation by the user. After deactivation, 
    * all user rewards will be transferred to him directly.
    */
    function deactivateLunchBox() public whenNotPaused updateReward(msg.sender) { 
        require(
            block.timestamp >= lastActivationTimePerUser[msg.sender] + 1 days,
            "SnacksPool: too early deactivation"
        );
        require(
            _lunchBoxParticipants.contains(msg.sender),
            "SnacksPool: not activated"
        );
        ILunchBox(lunchBox).getReward(msg.sender);
        _lunchBoxParticipants.remove(msg.sender);
        if (ISnacksBase(snacks).isExcludedHolder(msg.sender)) {
            _excludedHoldersLunchBoxSupply -= _balances[msg.sender];
        } else {
            _notExcludedHoldersLunchBoxSupply -= _balances[msg.sender];
        }
        rewards[msg.sender][snacks] = 0;
        rewards[msg.sender][btcSnacks] = 0;
        rewards[msg.sender][ethSnacks] = 0;
    }
    
    /**
    * @notice Withdraws the desired amount of deposited tokens for the user.
    * @dev If 24 hours have not passed since the last deposit by the user, 
    * a fee of 50% is charged from the withdrawn amount of deposited tokens
    * and sent to the Seniorage contract. The withdrawn amount of tokens cannot
    * exceed the amount of the deposit or be equal to 0.
    * @param amount_ Desired amount of tokens to withdraw.
    */
    function withdraw(
        uint256 amount_
    )
        public
        override
        whenNotPaused
        nonReentrant
        updateReward(msg.sender)
    {
        if (ISnacksBase(snacks).isExcludedHolder(msg.sender)) {
            require(
                amount_ > 0,
                "SnacksPool: can not withdraw 0"
            );
            if (_lunchBoxParticipants.contains(msg.sender)) {
                ILunchBox(lunchBox).updateRewardForUser(msg.sender);
                if (amount_ == _balances[msg.sender]) {
                    deactivateLunchBox();
                } else {
                    _excludedHoldersLunchBoxSupply -= amount_;
                }
            }
            _balances[msg.sender] -= amount_;
            _excludedHoldersSupply -= amount_;
        } else {
            uint256 adjustedAmount = amount_.div(ISnacksBase(snacks).adjustmentFactor());
            require(
                adjustedAmount > 0,
                "SnacksPool: invalid amount to withdraw"
            );
            if (_lunchBoxParticipants.contains(msg.sender)) {
                ILunchBox(lunchBox).updateRewardForUser(msg.sender);
                if (_balances[msg.sender] - adjustedAmount <= 1 wei) {
                    deactivateLunchBox();
                } else {
                    _notExcludedHoldersLunchBoxSupply -= adjustedAmount;
                }
            }
            if (_balances[msg.sender] - adjustedAmount <= 1 wei) {
                _balances[msg.sender] = 0;
            } else {
                _balances[msg.sender] -= adjustedAmount;
            }
            _notExcludedHoldersSupply -= adjustedAmount;
        }
        uint256 seniorageFeeAmount;
        if (block.timestamp < userLastDepositTime[msg.sender] + 1 days) {
            seniorageFeeAmount = amount_ / 2;
            IERC20(stakingToken).safeTransfer(seniorage, seniorageFeeAmount);
            IERC20(stakingToken).safeTransfer(msg.sender, amount_ - seniorageFeeAmount);
            emit Withdrawn(msg.sender, amount_ - seniorageFeeAmount);
        } else {
            IERC20(stakingToken).safeTransfer(msg.sender, amount_);
            emit Withdrawn(msg.sender, amount_);
        }
    }
    
    /**
    * @notice Transfers rewards to the user.
    * @dev If the user is a participant of the risk-free investment program, 
    * then the reward pattern for him becomes different.
    * Earned rewards are sent to the LunchBox contract and at the same time 
    * the LunchBox contract gives the user what is earned inside it. 
    * If the user is not a participant of the risk-free investment program, then
    * all earned rewards are transferred to him directly.
    */
    function getReward(  
    ) 
        public 
        override 
        whenNotPaused 
        nonReentrant 
        updateReward(msg.sender) 
    {
        if (_lunchBoxParticipants.contains(msg.sender)) {
            ILunchBox(lunchBox).getReward(msg.sender);
        } else {
            _getReward();
        }
    }

    /**
    * @notice Retrieves the user's deposit amount.
    * @dev User deposits are automatically increased as reward for holding takes into account holders deposits.
    * @param user_ User address.
    * @return Amount of the deposit.
    */
    function getBalance(address user_) public view override returns (uint256) {
        if (ISnacksBase(snacks).isExcludedHolder(user_)) {
            return _balances[user_];
        } else {
            return _balances[user_].mul(ISnacksBase(snacks).adjustmentFactor());
        }
    }

    /**
    * @notice Retrieves the total amount of deposited tokens.
    * @dev Since user deposits are automatically increased, total supply has the same behaviour.
    * @return Total amount of deposited tokens.
    */
    function getTotalSupply() public view override returns (uint256) {
        return 
            _notExcludedHoldersSupply.mul(ISnacksBase(snacks).adjustmentFactor())
            + _excludedHoldersSupply;
    }

    /**
    * @notice Retrieves the amount of rewards earned 
    * by the user in one of the reward tokens.
    * @dev Calculates earned reward from the last `userRewardPerTokenPaid` timestamp 
    * to the latest block timestamp time interval.
    * @param user_ User address.
    * @param rewardToken_ Address of one of the reward tokens.
    * @return Amount of rewards earned by the user in one of the reward tokens.
    */
    function earned(
        address user_,
        address rewardToken_
    )
        public
        view
        override
        onlyValidToken(rewardToken_)
        returns (uint256)
    {
        uint256 rewardPerTokenPaid = userRewardPerTokenPaid[rewardToken_][user_];
        if (!_adjusted[user_][_currentTotalSupplyFactorId.current()]) {
            rewardPerTokenPaid = rewardPerTokenPaid.div(_totalSupplyFactor);
        }
        return
            getBalance(user_)
            * (rewardPerToken(rewardToken_) - rewardPerTokenPaid)
            / 1e18
            + rewards[user_][rewardToken_];
    }

    /**
    * @notice Updates the reward earned by the user in one of the reward tokens.
    * @dev Called inside `updateRewardPerToken` modifier and `_updateAllRewards()` function.
    * It serves both purpose: gas savings and readability.
    * @param rewardToken_ Address of one of the reward tokens.
    * @param user_ User address.
    */
    function _updateReward(address rewardToken_, address user_) internal override {
        rewardPerTokenStored[rewardToken_] = rewardPerToken(rewardToken_);
        lastUpdateTimePerToken[rewardToken_] = lastTimeRewardApplicable(rewardToken_);
        if (user_ != address(0)) {
            rewards[user_][rewardToken_] = earned(user_, rewardToken_);
            if (!_adjusted[user_][_currentTotalSupplyFactorId.current()]) {
                _adjusted[user_][_currentTotalSupplyFactorId.current()] = true;
            }
            userRewardPerTokenPaid[rewardToken_][user_] = rewardPerTokenStored[rewardToken_];
        }
    }
}