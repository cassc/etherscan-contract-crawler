// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IRainiLpv3StakingPoolv2.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract RainiLpv3StakingPoolFunctions is AccessControl {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using SafeERC20 for IERC20; 

    IRainiLpv3StakingPoolv2 public lpStakingPool;

    uint256 public constant REWARD_DECIMALS = 1000000;
    uint256 public constant BONUS_DECIMALS = 1000000000;
    uint256 public constant PHOTON_REWARD_DECIMALS = 10000000000000;

    uint256 public fullBonusCutoff;
    uint256 public xphotonCutoff;

    // Events
    event PhotonWithdrawn(uint256 amount);

    event TokensStaked(address payer, uint256 amount, uint256 timestamp);
    event TokensWithdrawn(address owner, uint256 amount, uint256 timestamp);

    event UnicornPointsBurned(address owner, uint256 amount);
    event UnicornPointsMinted(address owner, uint256 amount);

    event RewardWithdrawn(address owner, uint256 amount, uint256 timestamp);

    constructor(address _lpStakingPoolAddress, uint256 _fullBonusCutoff) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        lpStakingPool = IRainiLpv3StakingPoolv2(_lpStakingPoolAddress);
        fullBonusCutoff = _fullBonusCutoff;
        xphotonCutoff = 2147483647;
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "not owner"
        );
        _;
    }

    modifier onlyBurner() {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "not burner"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "not minter"
        );
        _;
    }

    function balanceUpdate(address _owner) internal {
        IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = lpStakingPool.accountRewardVars(_owner);
        IRainiLpv3StakingPoolv2.AccountVars memory _accountVars = lpStakingPool.accountVars(_owner);
        IRainiLpv3StakingPoolv2.GeneralRewardVars memory _generalRewardVars = lpStakingPool.generalRewardVars();

        // Photon rewards
        _generalRewardVars.photonRewardPerTokenStored = uint64(
            photonRewardPerToken()
        );
        _generalRewardVars.lastUpdateTime = uint32(lastTimeRewardApplicable());

        if (_owner != address(0)) {
            uint32 duration = uint32(block.timestamp) -
                _accountRewardVars.lastUpdated;
            uint128 unicornReward = calculateReward(
                _owner,
                lpStakingPool.staked(_owner),
                duration,
                lpStakingPool.rewardRate(),
                true
            );
            uint32 xphotonDuration = uint32(Math.min(block.timestamp, xphotonCutoff)) - _accountRewardVars.lastUpdated;
            uint128 xphotonReward = calculateReward(
                _owner,
                lpStakingPool.staked(_owner),
                xphotonDuration,
                lpStakingPool.xphotonRewardRate(),
                false
            );

            _accountVars.unicornBalance = _accountVars.unicornBalance + unicornReward;
            _accountVars.xphotonBalance = _accountVars.xphotonBalance + xphotonReward;
            
            _accountRewardVars.lastUpdated = uint32(block.timestamp);
            _accountRewardVars.lastBonus = uint64(
                Math.min(
                    lpStakingPool.maxBonus(),
                    _accountRewardVars.lastBonus + lpStakingPool.bonusRate() * duration
                )
            );

            _accountRewardVars.photonRewards = uint96(photonEarned(_owner));
            _accountRewardVars.photonRewardPerTokenPaid = _generalRewardVars
                .photonRewardPerTokenStored;
        }

        lpStakingPool.setAccountRewardVars(_owner, _accountRewardVars);
        lpStakingPool.setAccountVars(_owner, _accountVars);
        lpStakingPool.setGeneralRewardVars(_generalRewardVars);
    }

    function setFullBonusCutoff(uint256 _fullBonusCutoff)
        external
        onlyOwner 
    {
        fullBonusCutoff = _fullBonusCutoff;
    }

    function setXphotonCutoff(uint256 _xphotonCutoff)
        external
        onlyOwner 
    {
        xphotonCutoff = _xphotonCutoff;
    }

    function setReward(uint256 _rewardRate, uint256 _xphotonRewardRate, uint256 _minRewardStake)
        external
        onlyOwner
    {
        lpStakingPool.setRewardRate(_rewardRate);
        lpStakingPool.setXphotonRewardRate(_xphotonRewardRate);
        lpStakingPool.setMinRewardStake(_minRewardStake);
    }

    function setBonus(uint256 _maxBonus, uint256 _bonusDuration)
        external
        onlyOwner
    {
        lpStakingPool.setMaxBonus(_maxBonus * BONUS_DECIMALS);
        lpStakingPool.setBonusDuration(_bonusDuration);
        lpStakingPool.setBonusRate(lpStakingPool.maxBonus() / _bonusDuration);
    }

    function setTickRange(int24 _maxTickLower, int24 _minTickUpper)
        external
        onlyOwner
    {
        lpStakingPool.setMinTickUpper(_minTickUpper);
        lpStakingPool.setMaxTickLower(_maxTickLower);
    }

    function setFeeRequired(uint24 _feeRequired) external onlyOwner {
        lpStakingPool.setFeeRequired(_feeRequired);
    }

    function stake(uint32 _tokenId)
        external        
    {
        balanceUpdate(_msgSender());

        (
            ,
            ,
            //uint96 nonce,
            //address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity, //uint256 feeGrowthInside0LastX128, //uint256 feeGrowthInside1LastX128, //uint128 tokensOwed0,
            ,
            ,
            ,

        ) = //uint128 tokensOwed1
            lpStakingPool.rainiLpNft().positions(_tokenId);

        require(
            tickUpper > lpStakingPool.minTickUpper(),
            "nft bad"
        );
        require(
            tickLower < lpStakingPool.maxTickLower(),
            "nft bad"
        );
        require(
            (token0 == lpStakingPool.exchangeTokenAddress() && token1 == lpStakingPool.rainiTokenAddress()) ||
                (token1 == lpStakingPool.exchangeTokenAddress() &&
                    token0 == lpStakingPool.rainiTokenAddress()),
            "nft bad"
        );
        require(fee ==lpStakingPool.feeRequired(), "fee bad");

        lpStakingPool.stakeLpNft(_msgSender(), _tokenId);

        lpStakingPool.setTotalSupply(lpStakingPool.totalSupply() + liquidity);

        uint256 currentStake = lpStakingPool.staked(_msgSender());    
        lpStakingPool.setStaked(_msgSender(), currentStake + liquidity);

        IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = lpStakingPool.accountRewardVars(_msgSender());

        if (block.timestamp <= fullBonusCutoff) {
            _accountRewardVars.lastBonus = uint64(lpStakingPool.maxBonus());
        } else {
            _accountRewardVars.lastBonus = uint64(
                (_accountRewardVars.lastBonus * currentStake) /
                    (currentStake + liquidity)
            );
        }

        lpStakingPool.setAccountRewardVars(_msgSender(), _accountRewardVars);

        emit TokensStaked(_msgSender(), liquidity, block.timestamp);
    }

    function withdraw(uint32 _tokenId)
        external
        
    {
        balanceUpdate(_msgSender());
        lpStakingPool.withdrawLpNft(_msgSender(), _tokenId);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            //uint96 nonce,
            //address operator,
            //address token0,
            //address token1,
            //uint24 fee,
            //int24 tickLower,
            //int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = lpStakingPool.rainiLpNft().positions(_tokenId);

        uint256 currentStake = lpStakingPool.staked(_msgSender());
        lpStakingPool.setStaked(_msgSender(), currentStake - liquidity);
        lpStakingPool.setTotalSupply(lpStakingPool.totalSupply() - liquidity);

        emit TokensWithdrawn(_msgSender(), liquidity, block.timestamp);
    }

    function mint(address[] calldata _addresses, uint256[] calldata _points)
        external
        onlyMinter
    {
        IRainiLpv3StakingPoolv2.AccountVars memory _accountVars;

        for (uint256 i = 0; i < _addresses.length; i++) {
            _accountVars = lpStakingPool.accountVars(_addresses[i]);
            _accountVars.unicornBalance = uint128(
                _accountVars.unicornBalance + _points[i]
            );
            lpStakingPool.setAccountVars(_addresses[i], _accountVars);
            emit UnicornPointsMinted(_addresses[i], _points[i]);
        }
    }

    function burn(address _owner, uint256 _amount)
        external
        onlyBurner        
    {
        balanceUpdate(_owner);
        IRainiLpv3StakingPoolv2.AccountVars memory _accountVars = lpStakingPool.accountVars(_owner);
        _accountVars.unicornBalance = uint128(
            _accountVars.unicornBalance - _amount
        );
        lpStakingPool.setAccountVars(_owner, _accountVars);

        emit UnicornPointsBurned(_owner, _amount);
    }

    function addPhotonRewardPool(uint256 _amount, uint256 _duration)
        external
        onlyOwner
    {
        balanceUpdate(address(0));
        IRainiLpv3StakingPoolv2.GeneralRewardVars memory _generalRewardVars = lpStakingPool.generalRewardVars();

        if (_generalRewardVars.periodFinish > block.timestamp) {
            uint256 timeRemaining = _generalRewardVars.periodFinish -
                block.timestamp;
            _amount += timeRemaining * _generalRewardVars.photonRewardRate;
        }

        lpStakingPool.photonToken().safeTransferFrom(_msgSender(), address(lpStakingPool), _amount);
        _generalRewardVars.photonRewardRate = uint128(_amount / _duration);
        _generalRewardVars.periodFinish = uint32(block.timestamp + _duration);
        _generalRewardVars.lastUpdateTime = uint32(block.timestamp);
        lpStakingPool.setGeneralRewardVars(_generalRewardVars);
    }

    function abortPhotonRewardPool()
        external
        onlyOwner
    {
        balanceUpdate(address(0));
        IRainiLpv3StakingPoolv2.GeneralRewardVars memory _generalRewardVars = lpStakingPool.generalRewardVars();

        require(
            _generalRewardVars.periodFinish > block.timestamp,
            "pool not active"
        );

        uint256 timeRemaining = _generalRewardVars.periodFinish -
            block.timestamp;
        uint256 remainingAmount = timeRemaining *
            _generalRewardVars.photonRewardRate;
        lpStakingPool.withdrawPhoton(_msgSender(), remainingAmount);

        _generalRewardVars.photonRewardRate = 0;
        _generalRewardVars.periodFinish = uint32(block.timestamp);
        _generalRewardVars.lastUpdateTime = uint32(block.timestamp);
        lpStakingPool.setGeneralRewardVars(_generalRewardVars);
    }

    function withdrawReward()
        external
    {
        balanceUpdate(_msgSender());
        uint256 reward = photonEarned(_msgSender());
        require(reward > 1, "no reward");
        if (reward > 1) {
            IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = 
                lpStakingPool.accountRewardVars(_msgSender());
            _accountRewardVars.photonRewards = 0;
            lpStakingPool.setAccountRewardVars(_msgSender(), _accountRewardVars);
            lpStakingPool.withdrawPhoton(_msgSender(), reward);
        }

        emit RewardWithdrawn(_msgSender(), reward, block.timestamp);
    }

    function withdrawXphoton(uint256 _amount) 
        external
    {
        balanceUpdate(_msgSender());     
        IRainiLpv3StakingPoolv2.AccountVars memory _accountVars = lpStakingPool.accountVars(_msgSender());
        _accountVars.xphotonBalance -= uint128(_amount);
        lpStakingPool.xphotonToken().mint(_msgSender(), _amount);
        lpStakingPool.setAccountVars(_msgSender(), _accountVars);
    }



    // Views
    
    function getRewardByDuration(
        address _owner,
        uint256 _amount,
        uint256 _duration
    ) public view returns (uint256) {
        return calculateReward(_owner, _amount, _duration, lpStakingPool.rewardRate(), true);
    }

    function getStaked(address _owner) public view returns (uint256) {
        return lpStakingPool.staked(_owner);
    }

    function getStakedPositions(address _owner)
        public
        view
        returns (uint32[] memory)
    {
        return lpStakingPool.getStakedPositions(_owner);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        uint256 reward = calculateReward(
            _owner,
            lpStakingPool.staked(_owner),
            block.timestamp - lpStakingPool.accountRewardVars(_owner).lastUpdated,
            lpStakingPool.rewardRate(),
            true
        );
        return lpStakingPool.accountVars(_owner).unicornBalance + reward;
    }

    function getCurrentBonus(address _owner) public view returns (uint256) {
        IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = lpStakingPool.accountRewardVars(_owner);

        if (lpStakingPool.staked(_owner) == 0) {
            return 0;
        }
        uint256 duration = block.timestamp - _accountRewardVars.lastUpdated;
        return
            Math.min(
                lpStakingPool.maxBonus(),
                _accountRewardVars.lastBonus + lpStakingPool.bonusRate() * duration
            );
    }

    function getCurrentAvgBonus(address _owner, uint256 _duration)
        public
        view
        returns (uint256)
    {
        IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = lpStakingPool.accountRewardVars(_owner);

        if (lpStakingPool.staked(_owner) == 0) {
            return 0;
        }
        uint256 avgBonus;
        if (_accountRewardVars.lastBonus < lpStakingPool.maxBonus()) {
            uint256 durationTillMax = (lpStakingPool.maxBonus() -
                _accountRewardVars.lastBonus) / lpStakingPool.bonusRate();
            if (_duration > durationTillMax) {
                uint256 avgWeightedBonusTillMax = ((_accountRewardVars
                    .lastBonus + lpStakingPool.maxBonus()) * durationTillMax) / 2;
                uint256 weightedMaxBonus = lpStakingPool.maxBonus() *
                    (_duration - durationTillMax);

                avgBonus =
                    (avgWeightedBonusTillMax + weightedMaxBonus) /
                    _duration;
            } else {
                avgBonus =
                    (_accountRewardVars.lastBonus +
                        lpStakingPool.bonusRate() *
                        _duration +
                        _accountRewardVars.lastBonus) /
                    2;
            }
        } else {
            avgBonus = lpStakingPool.maxBonus();
        }
        return avgBonus;
    }

    function calculateReward(
        address _owner,
        uint256 _amount,
        uint256 _duration,
        uint256 _rewardRate,
        bool _addBonus
    ) public view returns (uint128) {
        uint256 reward = (_duration * _rewardRate * _amount) /
            (REWARD_DECIMALS * lpStakingPool.minRewardStake());

        return _addBonus ? calculateBonus(_owner, reward, _duration) : uint128(reward);
    }

    function calculateBonus(
        address _owner,
        uint256 _amount,
        uint256 _duration
    ) public view returns (uint128) {
        uint256 avgBonus = getCurrentAvgBonus(_owner, _duration);
        return uint128(_amount + (_amount * avgBonus) / BONUS_DECIMALS / 100);
    }

    // PHOTON rewards

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, lpStakingPool.generalRewardVars().periodFinish);
    }

    function photonRewardPerToken() public view returns (uint256) {
        IRainiLpv3StakingPoolv2.GeneralRewardVars memory _generalRewardVars = lpStakingPool.generalRewardVars();

        if (lpStakingPool.totalSupply() == 0) {
            return _generalRewardVars.photonRewardPerTokenStored;
        }

        return
            _generalRewardVars.photonRewardPerTokenStored +
            (uint256(
                lastTimeRewardApplicable() - _generalRewardVars.lastUpdateTime
            ) *
                _generalRewardVars.photonRewardRate *
                PHOTON_REWARD_DECIMALS) /
            lpStakingPool.totalSupply();
    }

    function photonEarned(address account) public view returns (uint256) {
        IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = lpStakingPool.accountRewardVars(account);

        uint256 calculatedEarned = (uint256(lpStakingPool.staked(account)) *
            (photonRewardPerToken() -
                _accountRewardVars.photonRewardPerTokenPaid)) /
            PHOTON_REWARD_DECIMALS +
            _accountRewardVars.photonRewards;
        uint256 poolBalance = address(lpStakingPool.photonToken()) != address(0) ? lpStakingPool.photonToken().balanceOf(address(lpStakingPool)) : 0;
        // some rare case the reward can be slightly bigger than real number, we need to check against how much we have left in pool
        if (calculatedEarned > poolBalance) return poolBalance;
        return calculatedEarned;
    }


    function balanceOfXphoton(address _owner) public view returns (uint256) {
        uint256 reward = calculateReward(
            _owner,
            lpStakingPool.staked(_owner),
            uint32(Math.min(block.timestamp, xphotonCutoff)) - lpStakingPool.accountRewardVars(_owner).lastUpdated,
            lpStakingPool.xphotonRewardRate(),
            false
        );
        return lpStakingPool.accountVars(_owner).xphotonBalance + reward;
    }

}