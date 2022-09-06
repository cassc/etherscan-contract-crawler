// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: [email protected]
// Adapted from 0x7893bbb46613d7a4fbcc31dab4c9b823ffee1026

import "./interfaces/IGaugeController.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract GaugeIncentives is OwnableUpgradeable, UUPSUpgradeable {
    // Use SafeERC20 for transfers
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint constant WEEK = 86400 * 7;
    uint256 public constant DENOMINATOR = 10000; // denominates weights 10000 = 100%

    // Pitch Multisig with fee modeled after Votium.
    address public feeAddress;
    uint256 public platformFee;
    address public gaugeControllerAddress;
    
    // These mappings were made public, while the bribe.crv.finance implementation keeps them private.
    mapping(address => mapping(address => uint)) public currentlyClaimableRewards;
    mapping(address => mapping(address => uint)) public currentlyClaimedRewards;

    mapping(address => mapping(address => uint)) public activePeriod;
    mapping(address => mapping(address => mapping(address => uint))) public last_user_claim;

    // users can delegate their rewards to another address (key = delegator, value = delegate)
    mapping (address => address) public delegation;
    
    // list of addresses who have pushed pending rewards that should be checked on periodic update.
    mapping (address => mapping (address => address[])) public pendingRewardAddresses;
    
    mapping(address => address[]) _rewardsPerGauge;
    mapping(address => address[]) _gaugesPerReward;
    mapping(address => mapping(address => bool)) _rewardsInGauge;

    // Rewards are intrinsically tied to a certain price per vote.
    struct Reward {
        uint amount;
        uint pricePerPercent;
    }

    // pending rewards are indexed with [gauge][token][user]. each user can only have one reward per gauge per token.
    mapping (address => mapping (address => mapping (address => Reward))) public pendingPricedRewards;

    /* ========== INITIALIZER FUNCTION ========== */ 
    function initialize(address _feeAddress, uint256 _platformFee, address _gaugeControllerAddress) public initializer {
       __Context_init_unchained();
       __Ownable_init_unchained();
       feeAddress = _feeAddress;
       platformFee = _platformFee;
       gaugeControllerAddress = _gaugeControllerAddress;
    }
    /* ========== END INITIALIZER FUNCTION ========== */ 

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */
    function rewardsPerGauge(address _gauge) external view returns (address[] memory) {
        return _rewardsPerGauge[_gauge];
    }
    
    function gaugesPerReward(address _reward) external view returns (address[] memory) {
        return _gaugesPerReward[_reward];
    }

    function getPendingRewardAddresses(address _gauge, address _token) external view returns (address[] memory) {
        return pendingRewardAddresses[_gauge][_token];
    }

    function getPendingPricedRewards(address _gauge, address _token, address _user) external view returns (Reward memory) {
        return pendingPricedRewards[_gauge][_token][_user];
    }

    /**
     * @notice Returns a list of pending priced rewards for a given gauge and reward token.
     * @param _gauge The token underlying the supported gauge.
     * @param _token The incentive deposited on this gauge.
     * @return pendingPRs List of pending rewards.
     */
    function viewPendingPricedRewards(address _gauge, address _token) external view returns (Reward[] memory pendingPRs) {
        uint numPendingRewards = pendingRewardAddresses[_gauge][_token].length;

        pendingPRs = new Reward[](numPendingRewards);

        for (uint i = 0; i < numPendingRewards; i++) {
            address pendingRewardAddress = pendingRewardAddresses[_gauge][_token][i];
            pendingPRs[i] = pendingPricedRewards[_gauge][_token][pendingRewardAddress];
        }
    }

    /**
     * @notice Goes through every pending reward on a [gauge][token] pair and calculates the pending rewards.
     * @param _gauge The token underlying the supported gauge.
     * @param _token The incentive deposited on this gauge.
     * @return _amount the updated reward amount
     */
    function calculatePendingRewards(address _gauge, address _token) public view returns (uint _amount) {
        _amount = 0;

        for (uint i = 0; i < pendingRewardAddresses[_gauge][_token].length; i++) {
            address pendingRewardAddress = pendingRewardAddresses[_gauge][_token][i];
            uint _rewardAmount = viewGaugeReturn(_gauge, _token, pendingRewardAddress);
            _amount += _rewardAmount;
        }
    }
    
    /**
     * @notice Provides a user their quoted share of future rewards. If the contract's not synced with the controller, it'll reference the updated period.
     * @param _user Reward owner
     * @param _gauge The gauge being referenced by this function.
     * @param _token The incentive deposited on this gauge.
     * @return _amount The amount currently claimable
     */
    function claimable(address _user, address _gauge, address _token) external view returns (uint _amount) {
        _amount = 0;

        // current gauge period
        uint _currentPeriod = IGaugeController(gaugeControllerAddress).time_total();
        
        // last checkpointed period
        uint _checkpointedPeriod = activePeriod[_gauge][_token];

        // if now is past the active period, users are eligible to claim
        if (_currentPeriod > _checkpointedPeriod) {
            /* 
             * return indiv/total * (future + current)
             * start by collecting total slopes at the end of period
             */
            uint _totalWeight = IGaugeController(gaugeControllerAddress).points_weight(_gauge, _currentPeriod).bias;
            IGaugeController.VotedSlope memory _individualSlope = IGaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);

            /*
             * avoids a divide by zero problem. 
             * curve-style gauge controllers don't allow votes to kick in until 
             * the following period, so we don't need to track that ourselves 
             */
            if (_totalWeight > 0 && _individualSlope.end > 0) {
                uint _individualWeight = (_individualSlope.end - _currentPeriod) * _individualSlope.slope;
                uint _pendingRewardsAmount = calculatePendingRewards(_gauge, _token);

                /*
                 * includes:
                 * rewards available next period
                 * rewards qualified after the next period
                 * removes rewards that have been claimed
                 */
                uint _totalRewards = currentlyClaimableRewards[_gauge][_token] + _pendingRewardsAmount - currentlyClaimedRewards[_gauge][_token];
                _amount = (_totalRewards * _individualWeight) / _totalWeight;
            } 
        } else {
            // make sure we haven't voted or claimed in the past week
            uint _votingWeek = _checkpointedPeriod - WEEK;
            if (last_user_claim[_user][_gauge][_token] < _votingWeek) {
                uint _totalWeight = IGaugeController(gaugeControllerAddress).points_weight(_gauge, _checkpointedPeriod).bias;
                IGaugeController.VotedSlope memory _individualSlope = IGaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);

                if (_totalWeight > 0 && _individualSlope.end > 0) {
                    uint _individualWeight = (_individualSlope.end - _checkpointedPeriod) * _individualSlope.slope;
                    uint _totalRewards = currentlyClaimableRewards[_gauge][_token];
                    _amount = (_totalRewards * _individualWeight) / _totalWeight;
                }  
            }
        }
    }

    /**
     * @notice Checks whether or not the voter earned rewards have exceeded the originally deposited amount
     * @param _gauge The gauge being referenced by this function.
     * @param _token The incentive deposited on this gauge.
     * @param _pendingRewardAddress Address of rewards depositor
     * @return _amount The amount currently claimable
     */
    function earnedAmountExceedsDeposited(address _gauge, address _token, address _pendingRewardAddress) external view returns (bool) {
        Reward memory pr = pendingPricedRewards[_gauge][_token][_pendingRewardAddress];
        uint currentGaugeWeight = IGaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);
        return _voterEarnedRewards(pr.pricePerPercent, currentGaugeWeight) > pr.amount;
    }
    /* ========== END EXTERNAL VIEW FUNCTIONS ========== */

    /* ========== EXTERNAL FUNCTIONS ========== */
    /**
     * @notice Referenced from Gnosis' DelegateRegistry (https://github.com/gnosis/delegate-registry/blob/main/contracts/DelegateRegistry.sol)
     * @dev Sets a delegate for the msg.sender. Every msg.sender serves as a unique key.
     * @param delegate Address of the delegate
     */
    function setDelegate(address delegate) external {
        require (delegate != msg.sender, "Can't delegate to self");
        require (delegate != address(0), "Can't delegate to 0x0");
        address currentDelegate = delegation[msg.sender];
        require (delegate != currentDelegate, "Already delegated to this address");
        
        // Update delegation mapping
        delegation[msg.sender] = delegate;
        
        if (currentDelegate != address(0)) {
            emit ClearDelegate(msg.sender, currentDelegate);
        }

        emit SetDelegate(msg.sender, delegate);
    }
    
    /**
     * @notice Referenced from Gnosis' DelegateRegistry (https://github.com/gnosis/delegate-registry/blob/main/contracts/DelegateRegistry.sol)
     * @dev Clears a delegate for the msg.sender. Every msg.sender serves as a unique key.
     */
    function clearDelegate() external {
        address currentDelegate = delegation[msg.sender];
        require (currentDelegate != address(0), "No delegate set");
        
        // update delegation mapping
        delegation[msg.sender]= address(0);
        
        emit ClearDelegate(msg.sender, currentDelegate);
    }

    // if msg.sender is not user,
    function claimDelegatedReward(address _delegatingUser, address _delegatedUser, address _gauge, address _token) external returns (uint _amount) {
        require(delegation[_delegatingUser] == _delegatedUser, "Not the delegated address");
        _amount = _claimDelegatedReward(_delegatingUser, _delegatedUser, _gauge, _token);
        emit DelegateClaimed(_delegatingUser, _delegatedUser, _gauge, _token, _amount);
    }
    
    // if msg.sender is not user,
    function claimReward(address _user, address _gauge, address _token) external returns (uint _amount) {
        _amount = _claimReward(_user, _gauge, _token);
        emit Claimed(_user, _gauge, _token, _amount);
    }

    // if msg.sender is not user,
    function claimReward(address _gauge, address _token) external returns (uint _amount) {
        _amount = _claimReward(msg.sender, _gauge, _token);
        emit Claimed(msg.sender, _gauge, _token, _amount);
    }

    /**
     * @notice Deposits a reward on the gauge, which is stored in future claimable rewards. These will only be claimable once the contract has cleared the vote limit (measured 0 --> 10000 in bps percentage)
     * @param _gauge The gauge being updated by this function.
     * @param _token The incentive deposited on this gauge.
     * @param _amount The amount to deposit on this gauge.
     * @param _pricePerPercent The price paid per basis point of a vote.
     * @return The amount claimed.
     */
    function addRewardAmount(address _gauge, address _token, uint _amount, uint _pricePerPercent) external returns (bool) {
        require(!(
            pendingPricedRewards[_gauge][_token][msg.sender].pricePerPercent != 0 && 
            pendingPricedRewards[_gauge][_token][msg.sender].amount != 0
        ), "Pending reward already exists for sender. Please update instead.");
        require(_amount > 0, "Amount must be greater than 0");
        require(_pricePerPercent > 0, "Price per vote must be greater than 0");
        _updatePeriod(_gauge, _token);

        Reward memory newReward = Reward(_amount, _pricePerPercent);

        pendingPricedRewards[_gauge][_token][msg.sender] = newReward;
        pendingRewardAddresses[_gauge][_token].push(msg.sender);

        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        _add(_gauge, _token);
        return true;
    }

    /**
     * @notice Deposits a reward on the gauge, which is stored in future claimable rewards. These will only be claimable once the contract has cleared the vote limit (measured 0 --> 10000 in bps percentage)
     * @param _gauge The gauge being updated by this function.
     * @param _token The incentive deposited on this gauge.
     * @param _amount The amount to deposit on this gauge.
     * @param _pricePerPercent The price paid per basis point of a vote.
     * @return The amount claimed.
     */
    function updateRewardAmount(address _gauge, address _token, uint _amount, uint _pricePerPercent) external returns (bool) {
        Reward memory r = pendingPricedRewards[_gauge][_token][msg.sender];
        require(r.pricePerPercent != 0 && r.amount != 0, "Pending reward does not exist. Please pich a new reward.");
        require(_amount >= 0, "Amount must be greater than 0");
        require(_pricePerPercent >= r.pricePerPercent, "Price per vote must monotonically increase");
        require(_amount > 0 || _pricePerPercent > r.pricePerPercent, "Either price per vote or amount must increase");

        uint _newAmount = r.amount + _amount;

        Reward memory newReward = Reward(_newAmount, _pricePerPercent);

        pendingPricedRewards[_gauge][_token][msg.sender] = newReward;

        // replaced the amount variable with our incentiveTotal variable
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        return true;
    }

    /* ========== END EXTERNAL FUNCTIONS ========== */
    
    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Pure function to compute voter earned rewards
     * @param _pricePerPercent Set price per percent of votes
     * @param _gaugeWeight Ending gauge weight
     * @return Amount voters have earned
     */
    function _voterEarnedRewards(uint _pricePerPercent, uint _gaugeWeight) internal pure returns (uint) {
        return (_pricePerPercent * _gaugeWeight) / (1 * (10**16));
    }

    /**
     * @notice Claims a pro-rata share reward of a voting gauge. This can only be done once per period per reward token per gauge, which is enforced at the Gauge Controller level.
     * @param _user The reward claimer
     * @param _gauge The gauge being updated by this function.
     * @param _token The incentive deposited on this gauge.
     * @return _amount Amount claimed.
     */
    function _claimReward(address _user, address _gauge, address _token) internal returns (uint _amount) {
        _amount = 0;
        uint _period = _updatePeriod(_gauge, _token);
        uint _votingWeek = _period - WEEK;

        if (last_user_claim[_user][_gauge][_token] < _votingWeek) {
            uint _totalWeight = IGaugeController(gaugeControllerAddress).points_weight(_gauge, _period).bias; // bookmark the total slopes at the weds of current period
                
            if (_totalWeight > 0) {
                IGaugeController.VotedSlope memory _individualSlope = IGaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);
                uint _timeRemaining = _individualSlope.end - _period;
                uint _individualWeight = _timeRemaining * _individualSlope.slope;

                uint _totalRewards = currentlyClaimableRewards[_gauge][_token];
                _amount = _totalRewards * _individualWeight / _totalWeight;

                if (_amount > 0) {
                    currentlyClaimedRewards[_gauge][_token] += _amount;
                    last_user_claim[_user][_gauge][_token] = block.timestamp;
                    IERC20Upgradeable(_token).safeTransfer(_user, _amount);
                }
            }
        }
    }

    /**
     * @notice Claims a pro-rata share reward of a voting gauge. This can only be 
     * done once per period per reward token per gauge, which is enforced at the 
     * Gauge Controller level. This should be refactored for elegance eventually.
     * @param _delegatingUser The voter who's delegated their rewards.
     * @param _delegatedUser The delegated reward address.
     * @param _gauge The gauge being updated by this function.
     * @param _token The incentive deposited on this gauge.
     * @return _amount Amount claimed.
     */
    function _claimDelegatedReward(address _delegatingUser, address _delegatedUser, address _gauge, address _token) internal returns (uint _amount) {
        _amount = 0;
        uint _period = _updatePeriod(_gauge, _token);
        uint _votingWeek = _period - WEEK;

        if (last_user_claim[_delegatingUser][_gauge][_token] < _votingWeek) {
            // collect total slopes at end of period
            uint _totalWeight = IGaugeController(gaugeControllerAddress).points_weight(_gauge, _period).bias;
                
            if (_totalWeight > 0) {
                IGaugeController.VotedSlope memory _individualSlope = IGaugeController(gaugeControllerAddress).vote_user_slopes(_delegatingUser, _gauge);
                uint _timeRemaining = _individualSlope.end - _period;
                uint _individualWeight = _timeRemaining * _individualSlope.slope;

                uint _totalRewards = currentlyClaimableRewards[_gauge][_token];
                _amount = _totalRewards * _individualWeight / _totalWeight;

                if (_amount > 0) {
                    currentlyClaimedRewards[_gauge][_token] += _amount;
                    // sends the reward to the delegated user.
                    IERC20Upgradeable(_token).safeTransfer(_delegatedUser, _amount);
                }
            }
        }
    }

    /**
     * @notice Synchronizes this contract's period for a given (gauge, reward) pair with the Gauge Controller, checkpointing votes.
     * @param _gauge The token underlying the supported gauge.
     * @param _token The incentive deposited on this gauge.
     * @return _currentPeriod updated period
     */
    function _updatePeriod(address _gauge, address _token) internal returns (uint _currentPeriod) {
        // Period set to previous wednesday @ 5PM pt
        _currentPeriod = IGaugeController(gaugeControllerAddress).time_total();
        // Period needs to be set to next wednesday @ 5PM pt
        uint _checkpointedPeriod = activePeriod[_gauge][_token];

        if (_currentPeriod > _checkpointedPeriod) {
            IGaugeController(gaugeControllerAddress).checkpoint_gauge(_gauge);

            uint newlyQualifiedRewards = _updatePendingRewards(_gauge, _token);

            // add rewards that are newly qualified into this one
            currentlyClaimableRewards[_gauge][_token] += newlyQualifiedRewards;
            // subtract rewards that have already been claimed
            currentlyClaimableRewards[_gauge][_token] -= currentlyClaimedRewards[_gauge][_token];
            // 0 out the current claimed rewards... could be gas optimized because it's setting it to 0
            currentlyClaimedRewards[_gauge][_token] = 0;
            // syncs our storage with external period
            activePeriod[_gauge][_token] = _currentPeriod; 
        }
    }

    /**
     * @notice Goes through every pending reward on a [gauge][token] pair, calculates the amount on each vote incentive.
     * @param _gauge The token underlying the supported gauge.
     * @param _token The incentive deposited on this gauge.
     * @return _amount Updated pending rewards
     */
    function _updatePendingRewards(address _gauge, address _token) internal returns (uint _amount) {
        _amount = 0;
        uint pendingRewardAddressLength = pendingRewardAddresses[_gauge][_token].length;

        for (uint i = 0; i < pendingRewardAddressLength; i++) {
            address _pendingRewardAddress = pendingRewardAddresses[_gauge][_token][i];

            uint _lrAmount = calculatePendingGaugeAmount(_gauge, _token, _pendingRewardAddress);

            _amount += _lrAmount;

            pendingRewardAddresses[_gauge][_token][i] = pendingRewardAddresses[_gauge][_token][pendingRewardAddressLength-1];
            pendingRewardAddresses[_gauge][_token].pop();
            delete pendingPricedRewards[_gauge][_token][_pendingRewardAddress];
        }
    }

    function calculatePendingGaugeAmount(address _gauge, address _token, address _pendingRewardAddress) internal returns (uint _amount) {
        _amount = 0;
        Reward memory pr = pendingPricedRewards[_gauge][_token][_pendingRewardAddress];
        
        uint currentGaugeWeight = IGaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);
        uint voterEarnedRewards = _voterEarnedRewards(pr.pricePerPercent, currentGaugeWeight);

        IERC20Upgradeable rewardToken = IERC20Upgradeable(_token);

        if (voterEarnedRewards >= pr.amount) {
            // take the fee on the fully converted amount
            uint256 _fee = (pr.amount*platformFee)/DENOMINATOR;
            uint256 _incentiveTotal = pr.amount-_fee;

            _amount += _incentiveTotal;

            // transfer fee to fee address, doesn't take off the top
            rewardToken.safeTransfer(feeAddress, _fee);
        } else {
            uint _amountClaimable = voterEarnedRewards;
            uint256 _fee = (_amountClaimable * platformFee)/DENOMINATOR;

            // take the whole fee with no dilution
            if (pr.amount > (_amountClaimable + _fee)) {
                _amount += _amountClaimable;

                uint256 _amountToReturn = pr.amount - _amountClaimable - _fee;

                // take fee on the amount now claimable
                rewardToken.safeTransfer(feeAddress, _fee);

                // transfer the remainder to the original address
                rewardToken.safeTransfer(_pendingRewardAddress, _amountToReturn);
            } else {
                uint256 _totalFee = (pr.amount * platformFee)/DENOMINATOR;
                
                uint256 remainingReward = pr.amount - _totalFee;

                _amount += remainingReward;
                
                // take fee on the amount now claimable
                rewardToken.safeTransfer(feeAddress, _totalFee);
            }
        }
    }

    function viewGaugeReturn(address _gauge, address _token, address _pendingRewardAddress) internal view returns (uint) {
        Reward memory pr = pendingPricedRewards[_gauge][_token][_pendingRewardAddress];
        
        uint currentGaugeWeight = IGaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);

        uint expectedAmountOut = _voterEarnedRewards(pr.pricePerPercent, currentGaugeWeight);
        if (expectedAmountOut > pr.amount) {
            return pr.amount;
        } else {
            return expectedAmountOut;
        }
    }

    /**
     * @notice Adds the reward to internal bookkeeping for visibility at the contract level
     * @param _gauge The token underlying the supported gauge.
     * @param _reward The incentive deposited on this gauge.
     */
    function _add(address _gauge, address _reward) internal {
        if (!_rewardsInGauge[_gauge][_reward]) {
            _rewardsPerGauge[_gauge].push(_reward);
            _gaugesPerReward[_reward].push(_gauge);
            _rewardsInGauge[_gauge][_reward] = true;
        }
    }
    /* ========== END INTERNAL FUNCTIONS ========== */

    /* ========== OWNER FUNCTIONS ========== */
    // used to manage upgrading the contract
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function updateGaugeControllerAddress(address _gaugeControllerAddress) public onlyOwner {
      gaugeControllerAddress = _gaugeControllerAddress;
      emit UpdatedGaugeController(_gaugeControllerAddress);
    }

    // update fee address
    function updateFeeAddress(address _feeAddress) public onlyOwner {
      feeAddress = _feeAddress;
    }

    // update fee amount
    function updateFeeAmount(uint256 _feeAmount) public onlyOwner {
      require(_feeAmount < 400, "max fee"); // Max fee 4%
      platformFee = _feeAmount;
      emit UpdatedFee(_feeAmount);
    }

    // //recover tokens on this contract
    function recoverERC20(address _tokenAddress, address _withdrawTo) external onlyOwner {
        uint256 balance = IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
        IERC20Upgradeable(_tokenAddress).safeTransfer(_withdrawTo, balance);
    }

    /* ========== END OWNER FUNCTIONS ========== */

    /* ========== EVENTS ========== */
    event Claimed(address indexed user, address indexed gauge, address indexed token, uint256 amount);
    event DelegateClaimed(address indexed delegatingUser, address indexed delegatedUser, address indexed gauge, address token, uint256 amount);
    event UpdatedFee(uint256 _feeAmount);
    event UpdatedGaugeController(address gaugeController);
    event SetDelegate(address indexed delegator, address indexed delegate);
    event ClearDelegate(address indexed delegator, address indexed delegate);   
}