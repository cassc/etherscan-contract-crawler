// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

import "./interfaces/ILunchBox.sol";
import "./interfaces/ISnacksPool.sol";
import "./interfaces/IMultipleRewardPool.sol";
import "./interfaces/ISnacksBase.sol";
import "./interfaces/IRouter.sol";

contract LunchBox is ILunchBox, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;
    using PRBMathUD60x18 for uint256;
    
    struct Recipient {
        address wallet;
        uint256 percentage;
    }
    
    uint256 private constant BASE_PERCENT = 10000;
    
    uint256 public rewardsDuration = 12 hours;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 private _totalSupplyFactor = PRBMathUD60x18.fromUint(1);
    address public immutable busd;
    address public immutable btc;
    address public immutable eth;
    address public immutable router;
    address public zoinks;
    address public snacks;
    address public btcSnacks;
    address public ethSnacks;
    address public snacksPool;
    address public poolRewardDistributor;
    address public seniorage;
    Counters.Counter private _currentTotalSupplyFactorId;
    
    mapping(address => mapping(uint256 => bool)) private _adjusted;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public snacksAmountStoredFor;
    mapping(address => uint256) public btcSnacksAmountStoredFor;
    mapping(address => uint256) public ethSnacksAmountStoredFor;
    Recipient[] public recipients;
    
    event TotalSupplyFactorUpdated(
        uint256 indexed totalSupplyFactor, 
        uint256 indexed totalSupplyFactorId
    );
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event RecipientsUpdated(address[] indexed destinations, uint256[] percentages);
    
    modifier onlyPoolRewardDistributor {
        require(
            msg.sender == poolRewardDistributor,
            "LunchBox: caller is not the PoolRewardDistributor contract"
        );
        _;
    }
    
    modifier onlySnacksPool {
        require(
            msg.sender == snacksPool,
            "LunchBox: caller is not the SnacksPool contract"
        );
        _;
    }
    
    modifier onlySeniorage {
        require(
            msg.sender == seniorage,
            "LunchBox: caller is not the Seniorage contract"
        );
        _;
    }

    modifier onlySnacks {
        require(
            msg.sender == snacks,
            "LunchBox: caller is not the Snacks contract"
        );
        _;
    }
    
    modifier updateReward(address user_) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (user_ != address(0)) {
            rewards[user_] = earned(user_);
            if (!_adjusted[user_][_currentTotalSupplyFactorId.current()]) {
                _adjusted[user_][_currentTotalSupplyFactorId.current()] = true;
            }
            userRewardPerTokenPaid[user_] = rewardPerTokenStored;
        }
        _;
    }
    
    /**
    * @param busd_ Binance-Peg BUSD token address.
    * @param btc_ Binance-Peg BTCB token address.
    * @param eth_ Binance-Peg Ethereum token address.
    * @param router_ Router contract address (from PancakeSwap DEX).
    */
    constructor(
        address busd_,
        address btc_,
        address eth_,
        address router_
    ) {
        busd = busd_;
        btc = btc_;
        eth = eth_;
        router = router_;
        IERC20(btc_).approve(router_, type(uint256).max);
        IERC20(eth_).approve(router_, type(uint256).max);
    }
    
    /**
    * @notice Configures the contract.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param zoinks_ Zoinks token address.
    * @param snacks_ Snacks token address.
    * @param btcSnacks_ BtcSnacks token address.
    * @param ethSnacks_ EthSnacks token address.
    * @param snacksPool_ SnacksPool contract address.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    * @param seniorage_ Seniorage contract address.
    */
    function configure(
        address zoinks_,
        address snacks_,
        address btcSnacks_,
        address ethSnacks_,
        address snacksPool_,
        address poolRewardDistributor_,
        address seniorage_
    )
        external
        onlyOwner
    {
        zoinks = zoinks_;
        snacks = snacks_;
        btcSnacks = btcSnacks_;
        ethSnacks = ethSnacks_;
        snacksPool = snacksPool_;
        poolRewardDistributor = poolRewardDistributor_;
        seniorage = seniorage_;
        if (IERC20(zoinks_).allowance(address(this), router) == 0) {
            IERC20(zoinks_).approve(router, type(uint256).max);
        }
        if (IERC20(zoinks_).allowance(address(this), snacks_) == 0) {
            IERC20(zoinks_).approve(snacks_, type(uint256).max);
        }
        if (IERC20(btcSnacks_).allowance(address(this), btcSnacks_) == 0) {
            IERC20(btcSnacks_).approve(btcSnacks_, type(uint256).max);
        }
        if (IERC20(ethSnacks_).allowance(address(this), ethSnacks_) == 0) {
            IERC20(ethSnacks_).approve(ethSnacks_, type(uint256).max);
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
            uint256 totalSupply = ISnacksPool(snacksPool).getLunchBoxParticipantsTotalSupply();
            _totalSupplyFactor = totalSupply.div(totalSupplyBefore_);
            rewardPerTokenStored = rewardPerTokenStored.div(_totalSupplyFactor);
            _currentTotalSupplyFactorId.increment();
            emit TotalSupplyFactorUpdated(
                _totalSupplyFactor,
                _currentTotalSupplyFactorId.current()
            );
        }
    }
    
    /**
    * @notice Sets recipients of Binance-Peg BUSD token.
    * @dev Sum of recipient percentages must be equal to 100%.
    * @param wallets_ Recipient addresses.
    * @param percentages_ Recipient percentages.
    */
    function setRecipients(
        address[] memory wallets_,
        uint256[] memory percentages_
    )
        external
        onlyOwner
    {
        uint256 length = percentages_.length;
        require(
            wallets_.length == length &&
            length != 0,
            "LunchBox: invalid array lengths"
        );
        uint256 sum;
        for (uint256 i = 0; i < length; i++) {
            sum += percentages_[i];
        }
        require(
            sum == BASE_PERCENT,
            "LunchBox: invalid sum of percentages"
        );
        delete recipients;
        for (uint256 i = 0; i < length; i++) {
            Recipient memory recipient;
            recipient.wallet = wallets_[i];
            recipient.percentage = percentages_[i];
            recipients.push(recipient);
        }
        emit RecipientsUpdated(wallets_, percentages_);
    }

    /**
    * @notice Sets rewards duration.
    * @dev The logic is derived from the StakingRewards contract.
    * @param rewardsDuration_ New rewards duration value.
    */
    function setRewardsDuration(uint256 rewardsDuration_) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "LunchBox: duration cannot be changed now"
        );
        rewardsDuration = rewardsDuration_;
        emit RewardsDurationUpdated(rewardsDuration);
    }
    
    /**
    * @notice Deposits Binance-Peg BUSD tokens for the Seniorage contract.
    * @dev Called by the Seniorage contract once every 12 hours.
    * @param busdAmount_ Amount of Binance-Peg BUSD tokens to deposit.
    */
    function stakeForSeniorage(
        uint256 busdAmount_
    )
        external
        onlySeniorage
        updateReward(address(0))
    {
        if (busdAmount_ != 0) {
            IERC20(busd).safeTransferFrom(msg.sender, address(this), busdAmount_);
            for (uint256 i = 0; i < recipients.length; i++) {
                IERC20(busd).safeTransfer(
                    recipients[i].wallet,
                    busdAmount_ * recipients[i].percentage / BASE_PERCENT
                );
            }
        }
        emit Staked(msg.sender, busdAmount_);
    }
    
    /**
    * @notice Deposits tokens for the Seniorage contract.
    * @dev Called by the Seniorage contract once every 12 hours.
    * @param zoinksAmount_ Amount of Zoinks tokens to deposit.
    * @param btcAmount_ Amount of Binance-Peg BTCB tokens to deposit.
    * @param ethAmount_ Amount of Binance-Peg Ethereum tokens to deposit.
    * @param snacksAmount_ Amount of Snacks tokens to deposit.
    * @param btcSnacksAmount_ Amount of BtcSnacks tokens to deposit.
    * @param ethSnacksAmount_ Amount of EthSnacks tokens to deposit.
    * @param zoinksBusdAmountOutMin_ The minimal amount of tokens (slippage tolerance) for 
    * Zoinks token to Binance-Peg BUSD token swap.
    * @param btcBusdAmountOutMin_ The minimal amount of tokens (slippage tolerance) for 
    * Binance-Peg BTCB token to Binance-Peg BUSD token swap.
    * @param ethBusdAmountOutMin_ The minimal amount of tokens (slippage tolerance) for 
    * Binance-Peg Ethereum token to Binance-Peg BUSD token swap.
    */
    function stakeForSeniorage(
        uint256 zoinksAmount_,
        uint256 btcAmount_,
        uint256 ethAmount_,
        uint256 snacksAmount_,
        uint256 btcSnacksAmount_,
        uint256 ethSnacksAmount_,
        uint256 zoinksBusdAmountOutMin_,
        uint256 btcBusdAmountOutMin_,
        uint256 ethBusdAmountOutMin_
    )
        external
        onlySeniorage
        updateReward(address(0))
    {
        if (zoinksAmount_ != 0) {
            IERC20(zoinks).safeTransferFrom(msg.sender, address(this), zoinksAmount_);
        }
        if (btcAmount_ != 0) {
            IERC20(btc).safeTransferFrom(msg.sender, address(this), btcAmount_);
        }
        if (ethAmount_ != 0) {
            IERC20(eth).safeTransferFrom(msg.sender, address(this), ethAmount_);
        }
        if (snacksAmount_ != 0) {
            IERC20(snacks).safeTransferFrom(msg.sender, address(this), snacksAmount_);
            uint256 snacksAmountToRedeem = snacksAmount_ + snacksAmountStoredFor[msg.sender];
            if (ISnacksBase(snacks).sufficientBuyTokenAmountOnRedeem(snacksAmountToRedeem)) {
                // Return value is ignored.
                ISnacksBase(snacks).redeem(snacksAmountToRedeem);
                if (snacksAmountStoredFor[msg.sender] != 0) {
                    snacksAmountStoredFor[msg.sender] = 0;
                }
            } else {
                snacksAmountStoredFor[msg.sender] += snacksAmount_;
            }
        }
        if (btcSnacksAmount_ != 0) {
            IERC20(btcSnacks).safeTransferFrom(msg.sender, address(this), btcSnacksAmount_);
            uint256 btcSnacksAmountToRedeem = btcSnacksAmount_ + btcSnacksAmountStoredFor[msg.sender];
            if (ISnacksBase(btcSnacks).sufficientBuyTokenAmountOnRedeem(btcSnacksAmountToRedeem)) {
                // Return value is ignored.
                ISnacksBase(btcSnacks).redeem(btcSnacksAmountToRedeem);
                if (btcSnacksAmountStoredFor[msg.sender] != 0) {
                    btcSnacksAmountStoredFor[msg.sender] = 0;
                }
            } else {
                btcSnacksAmountStoredFor[msg.sender] += btcSnacksAmount_;
            }
        }
        if (ethSnacksAmount_ != 0) {
            IERC20(ethSnacks).safeTransferFrom(msg.sender, address(this), ethSnacksAmount_);
            uint256 ethSnacksAmountToRedeem = ethSnacksAmount_ + ethSnacksAmountStoredFor[msg.sender];
            if (ISnacksBase(ethSnacks).sufficientBuyTokenAmountOnRedeem(ethSnacksAmountToRedeem)) {
                // Return value is ignored.
                ISnacksBase(ethSnacks).redeem(ethSnacksAmountToRedeem);
                if (ethSnacksAmountStoredFor[msg.sender] != 0) {
                    ethSnacksAmountStoredFor[msg.sender] = 0;
                }
            } else {
                ethSnacksAmountStoredFor[msg.sender] += ethSnacksAmount_;
            }
        }
        uint256 busdAmount;
        address[] memory path = new address[](2);
        path[1] = busd;
        uint256[] memory amounts = new uint256[](2);
        uint256 zoinksBalance = IERC20(zoinks).balanceOf(address(this));
        if (zoinksBalance != 0) {
            path[0] = zoinks;
            amounts = IRouter(router).swapExactTokensForTokens(
                zoinksBalance,
                zoinksBusdAmountOutMin_,
                path,
                address(this),
                block.timestamp
            );
            busdAmount += amounts[1];
        }
        uint256 btcBalance = IERC20(btc).balanceOf(address(this));
        if (btcBalance != 0) {
            path[0] = btc;
            amounts = IRouter(router).swapExactTokensForTokens(
                btcBalance,
                btcBusdAmountOutMin_,
                path,
                address(this),
                block.timestamp
            );
            busdAmount += amounts[1];
        }
        uint256 ethBalance = IERC20(eth).balanceOf(address(this));
        if (ethBalance != 0) {
            path[0] = eth;
            amounts = IRouter(router).swapExactTokensForTokens(
                ethBalance,
                ethBusdAmountOutMin_,
                path,
                address(this),
                block.timestamp
            );
            busdAmount += amounts[1];
        }
        if (busdAmount != 0) {
            for (uint256 i = 0; i < recipients.length; i++) {
                IERC20(busd).safeTransfer(
                    recipients[i].wallet,
                    busdAmount * recipients[i].percentage / BASE_PERCENT
                );
            }
        }
        emit Staked(msg.sender, busdAmount);
    }
    
    /**
    * @notice Deposits tokens for all participants.
    * @dev Mind that the function updates time variables through `updateReward` modifier.
    * Called by the SnacksPool contract once every 12 hours.
    * @param snacksAmount_ Amount of Snacks tokens to deposit.
    * @param btcSnacksAmount_ Amount of BtcSnacks tokens to deposit.
    * @param ethSnacksAmount_ Amount of EthSnacks tokens to deposit.
    * @param zoinksBusdAmountOutMin_ The minimal amount of tokens (slippage tolerance) for 
    * Zoinks token to Binance-Peg BUSD token swap.
    * @param btcBusdAmountOutMin_ The minimal amount of tokens (slippage tolerance) for 
    * Binance-Peg BTCB token to Binance-Peg BUSD token swap.
    * @param ethBusdAmountOutMin_ The minimal amount of tokens (slippage tolerance) for 
    * Binance-Peg Ethereum token to Binance-Peg BUSD token swap.
    */
    function stakeForSnacksPool(
        uint256 snacksAmount_,
        uint256 btcSnacksAmount_,
        uint256 ethSnacksAmount_,
        uint256 zoinksBusdAmountOutMin_,
        uint256 btcBusdAmountOutMin_,
        uint256 ethBusdAmountOutMin_
    )
        external
        onlySnacksPool
        updateReward(address(0))
    {
        uint256 busdAmount;
        address[] memory path = new address[](2);
        path[1] = busd;
        uint256[] memory amounts = new uint256[](2);
        if (snacksAmount_ != 0) {
            IERC20(snacks).safeTransferFrom(msg.sender, address(this), snacksAmount_);
            uint256 snacksAmountToRedeem = snacksAmount_ + snacksAmountStoredFor[msg.sender];
            if (ISnacksBase(snacks).sufficientBuyTokenAmountOnRedeem(snacksAmountToRedeem)) {
                uint256 zoinksAmount = ISnacksBase(snacks).redeem(snacksAmountToRedeem);
                path[0] = zoinks;
                amounts = IRouter(router).swapExactTokensForTokens(
                    zoinksAmount,
                    zoinksBusdAmountOutMin_,
                    path,
                    address(this),
                    block.timestamp
                );
                busdAmount += amounts[1];
                if (snacksAmountStoredFor[msg.sender] != 0) {
                    snacksAmountStoredFor[msg.sender] = 0;
                }
            } else {
                snacksAmountStoredFor[msg.sender] += snacksAmount_;
            }
        }
        if (btcSnacksAmount_ != 0) {
            IERC20(btcSnacks).safeTransferFrom(msg.sender, address(this), btcSnacksAmount_);
            uint256 btcSnacksAmountToRedeem = btcSnacksAmount_ + btcSnacksAmountStoredFor[msg.sender];
            if (ISnacksBase(btcSnacks).sufficientBuyTokenAmountOnRedeem(btcSnacksAmountToRedeem)) {
                uint256 btcAmount = ISnacksBase(btcSnacks).redeem(btcSnacksAmountToRedeem);
                path[0] = btc;
                amounts = IRouter(router).swapExactTokensForTokens(
                    btcAmount,
                    btcBusdAmountOutMin_,
                    path,
                    address(this),
                    block.timestamp
                );
                busdAmount += amounts[1];
                if (btcSnacksAmountStoredFor[msg.sender] != 0) {
                    btcSnacksAmountStoredFor[msg.sender] = 0;
                }
            } else {
                btcSnacksAmountStoredFor[msg.sender] += btcSnacksAmount_;
            }
        }
        if (ethSnacksAmount_ != 0) {
            IERC20(ethSnacks).safeTransferFrom(msg.sender, address(this), ethSnacksAmount_);
            uint256 ethSnacksAmountToRedeem = ethSnacksAmount_ + ethSnacksAmountStoredFor[msg.sender];
            if (ISnacksBase(ethSnacks).sufficientBuyTokenAmountOnRedeem(ethSnacksAmountToRedeem)) {
                uint256 ethAmount = ISnacksBase(ethSnacks).redeem(ethSnacksAmountToRedeem);
                path[0] = eth;
                amounts = IRouter(router).swapExactTokensForTokens(
                    ethAmount,
                    ethBusdAmountOutMin_,
                    path,
                    address(this),
                    block.timestamp
                );
                busdAmount += amounts[1];
                if (ethSnacksAmountStoredFor[msg.sender] != 0) {
                    ethSnacksAmountStoredFor[msg.sender] = 0;
                }
            } else {
                ethSnacksAmountStoredFor[msg.sender] += ethSnacksAmount_;
            }
        }
        if (busdAmount != 0) {
            for (uint256 i = 0; i < recipients.length; i++) {
                IERC20(busd).safeTransfer(
                    recipients[i].wallet,
                    busdAmount * recipients[i].percentage / BASE_PERCENT
                );
            }
        }
        emit Staked(msg.sender, busdAmount);
    }

    /**
    * @notice Transfers rewards to the user.
    * @dev Earned amount of Binance-Peg BUSD token is converted into Snacks token 
    * and sent to the user if this amount is enough for conversion,
    * otherwise earned tokens remain on the contract and continue to belong to the user 
    * until this amount is enough for conversion. Could be called only by the SnacksPool contract. 
    * @param user_ User address.
    */
    function getReward(
        address user_
    )
        external
        onlySnacksPool
        updateReward(user_)
    {
        uint256 reward = rewards[user_];
        if (reward > 0) {
            rewards[user_] = 0;
            IERC20(snacks).safeTransfer(user_, reward);
            emit RewardPaid(user_, reward);
        }
    }
        
    /**
    * @notice Notifies the contract of an incoming reward and recalculates the reward rate.
    * @dev Called by the PoolRewardDistributor contract once every 12 hours.
    * @param reward_ Reward amount.
    */
    function notifyRewardAmount(
        uint256 reward_
    )
        external
        onlyPoolRewardDistributor
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward_ / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward_ + leftover) / rewardsDuration;
        }
        uint256 balance = IERC20(snacks).balanceOf(address(this));
        require(
            rewardRate <= balance / rewardsDuration,
            "LunchBox: provided reward too high"
        );
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward_);
    }
    
    /**
    * @notice Updates reward for the user.
    * @dev The logic is derived from the StakingRewards contract.
    * @param user_ User address.
    */
    function updateRewardForUser(address user_) external onlySnacksPool updateReward(user_) {}
    
    /**
    * @notice Retrieves last time reward was applicable.
    * @dev The logic is derived from the StakingRewards contract.
    * @return Last time reward was applicable.
    */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }
    
    /**
    * @notice Retrieves the amount of reward per token staked.
    * @dev The logic is derived from the StakingRewards contract.
    * @return Amount of reward per token staked.
    */
    function rewardPerToken() public view returns (uint256) {
        uint256 totalSupply = ISnacksPool(snacksPool).getLunchBoxParticipantsTotalSupply();
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            (lastTimeRewardApplicable() - lastUpdateTime)
            * rewardRate
            * 1e18
            / totalSupply
            + rewardPerTokenStored;
    }
    
    /**
    * @notice Retrieves the amount of reward tokens earned by the user.
    * @dev The logic is derived from the StakingRewards contract.
    * @param user_ User address.
    * @return Amount of reward tokens earned by the user.
    */
    function earned(address user_) public view returns (uint256) {
        uint256 rewardPerTokenPaid = userRewardPerTokenPaid[user_];
        if (!_adjusted[user_][_currentTotalSupplyFactorId.current()]) {
            rewardPerTokenPaid = rewardPerTokenPaid.div(_totalSupplyFactor);
        }
        uint256 result = 
            IMultipleRewardPool(snacksPool).getBalance(user_)
            * (rewardPerToken() - rewardPerTokenPaid)
            / 1e18
            + rewards[user_];
        return ISnacksPool(snacksPool).isLunchBoxParticipant(user_) ? result : 0;
    }
}