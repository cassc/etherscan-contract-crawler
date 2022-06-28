//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./MorpherState.sol";
import "./MorpherUserBlocking.sol";
import "./MorpherToken.sol";

// ----------------------------------------------------------------------------------
// Staking Morpher Token generates interest
// The interest is set to 0.015% a day or ~5.475% in the first year
// Stakers will be able to vote on all ProtocolDecisions in MorpherGovernance (soon...)
// There is a lockup after staking or topping up (30 days) and a minimum stake (100k MPH)
// ----------------------------------------------------------------------------------

contract MorpherStaking is Initializable, ContextUpgradeable {

    MorpherState state;

    uint256 constant PRECISION = 10**8;
    uint256 constant INTERVAL  = 1 days;

    bytes32 constant public ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");
    bytes32 constant public STAKINGADMIN_ROLE = keccak256("STAKINGADMIN_ROLE");

    //mapping(address => uint256) private poolShares;
    //mapping(address => uint256) private lockup;

    uint256 public poolShareValue;
    uint256 public lastReward;
    uint256 public totalShares;
    //uint256 public interestRate = 15000; // 0.015% per day initially, diminishing returns over time
    struct InterestRate {
        uint256 validFrom;
        uint256 rate;
    }

    mapping(uint256 => InterestRate) public interestRates;
    uint256 public numInterestRates;

    uint256 public lockupPeriod; // to prevent tactical staking and ensure smooth governance
    uint256 public minimumStake; // 100k MPH minimum

    address public stakingAddress;
    bytes32 public marketIdStakingMPH; //STAKING_MPH

    struct PoolShares {
        uint256 numPoolShares;
        uint256 lockedUntil;
    }
    mapping(address => PoolShares) public poolShares;

// ----------------------------------------------------------------------------
// Events
// ----------------------------------------------------------------------------
    event SetInterestRate(uint256 newInterestRate);
    event InterestRateAdded(uint256 interestRate, uint256 validFromTimestamp);
    event InterestRateRateChanged(uint256 interstRateIndex, uint256 oldvalue, uint256 newValue);
    event InterestRateValidFromChanged(uint256 interstRateIndex, uint256 oldvalue, uint256 newValue);
    event SetLockupPeriod(uint256 newLockupPeriod);
    event SetMinimumStake(uint256 newMinimumStake);
    event LinkState(address stateAddress);
    
    event PoolShareValueUpdated(uint256 indexed lastReward, uint256 poolShareValue);
    event StakingRewardsMinted(uint256 indexed lastReward, uint256 delta);
    event Staked(address indexed userAddress, uint256 indexed amount, uint256 poolShares, uint256 lockedUntil);
    event Unstaked(address indexed userAddress, uint256 indexed amount, uint256 poolShares);
    
    
    modifier onlyRole(bytes32 role) {
        require(MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(role, _msgSender()), "MorpherToken: Permission denied.");
        _;
    }

    modifier userNotBlocked {
        require(!MorpherUserBlocking(state.morpherUserBlockingAddress()).userIsBlocked(msg.sender), "MorpherStaking: User is blocked");
        _;
    }
    
    function initialize(address _morpherState) public initializer {
        ContextUpgradeable.__Context_init();

        state = MorpherState(_morpherState);
        
        lastReward = block.timestamp;
        lockupPeriod = 30 days; // to prevent tactical staking and ensure smooth governance
        minimumStake = 10**23; // 100k MPH minimum
        stakingAddress = 0x2222222222222222222222222222222222222222;
        marketIdStakingMPH = 0x9a31fdde7a3b1444b1befb10735dcc3b72cbd9dd604d2ff45144352bf0f359a6; //STAKING_MPH
        poolShareValue = PRECISION;
        emit SetLockupPeriod(lockupPeriod);
        emit SetMinimumStake(minimumStake);
        // missing: transferOwnership to Governance once deployed
    }

// ----------------------------------------------------------------------------
// updatePoolShareValue
// Updates the value of the Pool Shares and returns the new value.
// Staking rewards are linear, there is no compound interest.
// ----------------------------------------------------------------------------
    
    function updatePoolShareValue() public returns (uint256 _newPoolShareValue) {
        if (block.timestamp >= lastReward + INTERVAL) {
            uint256 _numOfIntervals = block.timestamp - lastReward / INTERVAL;
            poolShareValue = poolShareValue + (_numOfIntervals * interestRate());
            lastReward = lastReward + (_numOfIntervals * (INTERVAL));
            emit PoolShareValueUpdated(lastReward, poolShareValue);
        }
        //mintStakingRewards(); //burning/minting does not influence this
        return poolShareValue;        
    }

// ----------------------------------------------------------------------------
// Staking rewards are minted if necessary
// ----------------------------------------------------------------------------

    // function mintStakingRewards() private {
    //     uint256 _targetBalance = poolShareValue * (totalShares);
    //     if (MorpherToken(state.morpherTokenAddress()).balanceOf(stakingAddress) < _targetBalance) {
    //         // If there are not enough token held by the contract, mint them
    //         uint256 _delta = _targetBalance - (MorpherToken(state.morpherTokenAddress()).balanceOf(stakingAddress));
    //         MorpherToken(state.morpherTokenAddress()).mint(stakingAddress, _delta);
    //         emit StakingRewardsMinted(lastReward, _delta);
    //     }
    // }

// ----------------------------------------------------------------------------
// stake(uint256 _amount)
// User specifies an amount they intend to stake. Pool Shares are issued accordingly
// and the _amount is transferred to the staking contract
// ----------------------------------------------------------------------------

    function stake(uint256 _amount) public userNotBlocked returns (uint256 _poolShares) {
        require(MorpherToken(state.morpherTokenAddress()).balanceOf(msg.sender) >= _amount, "MorpherStaking: insufficient MPH token balance");
        updatePoolShareValue();
        _poolShares = _amount / (poolShareValue);
        uint _numOfShares = poolShares[msg.sender].numPoolShares;
        require(minimumStake <= _numOfShares + _poolShares * poolShareValue, "MorpherStaking: stake amount lower than minimum stake");
        MorpherToken(state.morpherTokenAddress()).burn(msg.sender, _poolShares * (poolShareValue));
        totalShares = totalShares + (_poolShares);
        poolShares[msg.sender].numPoolShares = _numOfShares + _poolShares;
        poolShares[msg.sender].lockedUntil = block.timestamp + lockupPeriod;
        emit Staked(msg.sender, _amount, _poolShares, block.timestamp + (lockupPeriod));
        return _poolShares;
    }

// ----------------------------------------------------------------------------
// unstake(uint256 _amount)
// User specifies number of Pool Shares they want to unstake. 
// Pool Shares get deleted and the user receives their MPH plus interest
// ----------------------------------------------------------------------------

    function unstake(uint256 _numOfShares) public userNotBlocked returns (uint256 _amount) {
        uint256 _numOfExistingShares = poolShares[msg.sender].numPoolShares;
        require(_numOfShares <= _numOfExistingShares, "MorpherStaking: insufficient pool shares");

        uint256 lockedInUntil = poolShares[msg.sender].lockedUntil;
        require(block.timestamp >= lockedInUntil, "MorpherStaking: cannot unstake before lockup expiration");
        updatePoolShareValue();
        poolShares[msg.sender].numPoolShares = poolShares[msg.sender].numPoolShares - _numOfShares;
        totalShares = totalShares - _numOfShares;
        _amount = _numOfShares * poolShareValue;
        MorpherToken(state.morpherTokenAddress()).mint(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount, _numOfShares);
        return _amount;
    }

// ----------------------------------------------------------------------------
// Administrative functions
// ----------------------------------------------------------------------------

    function setMorpherStateAddress(address _stateAddress) public onlyRole(ADMINISTRATOR_ROLE) {
        state = MorpherState(_stateAddress);
        emit LinkState(_stateAddress);
    }

    /**
    Interest rate
     */
    function setInterestRate(uint256 _interestRate) public onlyRole(STAKINGADMIN_ROLE) {
        addInterestRate(_interestRate, block.timestamp);
    }

/**
    fallback function in case the old tradeengine asks for the current interest rate
 */
    function interestRate() public view returns (uint256) {
        //start with the last one, as its most likely the last active one, no need to run through the whole map
        if(numInterestRates == 0) {
            return 0;
        }
        for(uint256 i = numInterestRates - 1; i >= 0; i--) {
            if(interestRates[i].validFrom <= block.timestamp) {
                return interestRates[i].rate;
            }
        }
        return 0;
    }

    function addInterestRate(uint _rate, uint _validFrom) public onlyRole(STAKINGADMIN_ROLE) {
        require(numInterestRates == 0 || interestRates[numInterestRates-1].validFrom < _validFrom, "MorpherStaking: Interest Rate Valid From must be later than last interestRate");
        //omitting rate sanity checks here. It should always be smaller than 100% (100000000) but I'll leave that to the common sense of the admin.
        updatePoolShareValue();
        interestRates[numInterestRates].validFrom = _validFrom;
        interestRates[numInterestRates].rate = _rate;
        numInterestRates++;
        emit InterestRateAdded(_rate, _validFrom);
    }

    function changeInterestRateValue(uint256 _numInterestRate, uint256 _rate) public onlyRole(STAKINGADMIN_ROLE) {
        emit InterestRateRateChanged(_numInterestRate, interestRates[_numInterestRate].rate, _rate);
        updatePoolShareValue();
        interestRates[_numInterestRate].rate = _rate;
    }
    function changeInterestRateValidFrom(uint256 _numInterestRate, uint256 _validFrom) public onlyRole(STAKINGADMIN_ROLE) {
        emit InterestRateValidFromChanged(_numInterestRate, interestRates[_numInterestRate].validFrom, _validFrom);
        require(numInterestRates > _numInterestRate, "MorpherStaking: Interest Rate Does not exist!");
        require(
            (_numInterestRate == 0 && numInterestRates-1 > 0 && interestRates[_numInterestRate+1].validFrom > _validFrom) || //we change the first one and there exist more than one
            (_numInterestRate > 0 && _numInterestRate == numInterestRates-1 && interestRates[_numInterestRate - 1].validFrom < _validFrom) || //we changed the last one
            (_numInterestRate > 0 && _numInterestRate < numInterestRates-1 && interestRates[_numInterestRate - 1].validFrom < _validFrom && interestRates[_numInterestRate + 1].validFrom > _validFrom),
            "MorpherStaking: validFrom cannot be smaller than previous Interest Rate or larger than next Interest Rate"
            );
        updatePoolShareValue();
        interestRates[_numInterestRate].validFrom = _validFrom;
    }

     function getInterestRate(uint256 _positionTimestamp) public view returns(uint256) {
        uint256 sumInterestRatesWeighted = 0;
        uint256 startingTimestamp = 0;
        
        for(uint256 i = 0; i < numInterestRates; i++) {
            if(i == numInterestRates-1 || interestRates[i+1].validFrom > block.timestamp) {
                //reached last interest rate
                sumInterestRatesWeighted = sumInterestRatesWeighted + (interestRates[i].rate * (block.timestamp - interestRates[i].validFrom));
                if(startingTimestamp == 0) {
                    startingTimestamp = interestRates[i].validFrom;
                }
                break; //in case there are more in the future
            } else {
                //only take interest rates after the position was created
                if(interestRates[i+1].validFrom > _positionTimestamp) {
                    sumInterestRatesWeighted = sumInterestRatesWeighted + (interestRates[i].rate * (interestRates[i+1].validFrom - interestRates[i].validFrom));
                    if(interestRates[i].validFrom <= _positionTimestamp) {
                        startingTimestamp = interestRates[i].validFrom;
                    }
                }
            } 
        }
        uint interestRateInternal = sumInterestRatesWeighted / (block.timestamp - startingTimestamp);
        return interestRateInternal;

    }

    function setLockupPeriodRate(uint256 _lockupPeriod) public onlyRole(STAKINGADMIN_ROLE) {
        lockupPeriod = _lockupPeriod;
        emit SetLockupPeriod(_lockupPeriod);
    }
    
    function setMinimumStake(uint256 _minimumStake) public onlyRole(STAKINGADMIN_ROLE) {
        minimumStake = _minimumStake;
        emit SetMinimumStake(_minimumStake);
    }

// ----------------------------------------------------------------------------
// Getter functions
// ----------------------------------------------------------------------------

    function getTotalPooledValue() public view returns (uint256 _totalPooled) {
        // Only accurate if poolShareValue is up to date
        return poolShareValue * (totalShares);
    }

    function getStake(address _address) public view returns (uint256 _poolShares) {
        return poolShares[_address].numPoolShares;
    }

    function getStakeValue(address _address) public view returns(uint256 _value, uint256 _lastUpdate) {
        // Only accurate if poolShareValue is up to date
        return (getStake(_address) * (poolShareValue), lastReward);
    }
}