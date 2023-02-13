// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./utils/SpookyAuth.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20Ext is IERC20 {
    function decimals() external returns (uint);
}

// The goal of this farm is to allow a stake xBoo earn anything model
// In a flip of a traditional farm, this contract only accepts xBOO as the staking token
// Each new pool added is a new reward token, each with its own start times
// end times, and rewards per second.
contract AceLab is SpookyAuth, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    // Info of each user.
    struct UserInfo {
        uint amount;     // How many tokens the user has provided.
        uint rewardDebt; // Reward debt. See explanation below.
        uint catDebt;    // Cat debt. See explanation below.
        uint mp;         // Total staked magicat power, sum of all magicat rarities staked by this user in this pool [uint64 enough]
    }

    // Info of each pool.
    struct PoolInfo { //full slot = 32B
        IERC20 RewardToken;           //20B Address of reward token contract.
        // uint32 userLimitEndTime;      //4B
        uint8 TokenPrecision;         //1B The precision factor used for calculations, equals the tokens decimals
                                      //7B [free space available here]

        uint xBooStakedAmount;        //32B # of xboo allocated to this pool
        uint mpStakedAmount;          //32B # of mp allocated to this pool

        uint RewardPerSecond;         //32B reward token per second for this pool in wei
        uint accRewardPerShare;       //32B Accumulated reward per share, times the pools token precision. See below.
        uint accRewardPerShareMagicat;//32B Accumulated reward per share, times the pools token precision. See below.

        address protocolOwnerAddress; //20B this address is the owner of the protocol corresponding to the reward token, used for emergency withdraw to them only
        uint32 lastRewardTime;        //4B Last block time that reward distribution occurs.
        uint32 endTime;               //4B end time of pool
        uint32 startTime;             //4B start time of pool
    }

    //remember that this should be *1000 of the apparent value since onchain rarities are multiplied by 1000, also remember that this is per 1e18 wei of xboo.
    uint mpPerXboo = 300 * 1000;

    IERC20 public immutable xboo;
    // uint32 public baseUserLimitTime = 2 days;
    // uint public baseUserLimit;

    IERC721 public immutable magicat;
    uint32 public magicatBoost = 1000;
    bool public emergencyCatWithdrawable = false;

    // Info of each pool.
    mapping (uint => PoolInfo) public poolInfo;
    // Number of pools
    uint public poolAmount;
    // Info of each user that stakes tokens.
    mapping (uint => mapping (address => UserInfo)) public userInfo;
    // Info of each users set of staked magicats per pool (pool => (user => magicats))
    mapping (uint => mapping (address => EnumerableSet.UintSet)) _stakedMagicats; //this data type cant be public, use getter getStakedMagicats()
    // Total staked amount of xboo in all pools by user
    mapping (address => uint) public balanceOf;
    // Sum of all rarities of all staked magicats
    uint public stakedMagicatPower;
    // Max total magicat power
    // uint public constant MAX_MAGICAT_POWER = 10627876002;
    uint public constant MAX_MAGICAT_POWER = 1000;
    // precisionOf[i] = 10**(30 - i)
    mapping (uint8 => uint) public precisionOf;
    mapping (address => bool) public isRewardToken;

    event AdminTokenRecovery(address tokenRecovered, uint amount);
    event Deposit(address indexed user, uint indexed pid, uint amount);
    event Withdraw(address indexed user, uint indexed pid, uint amount);
    event EmergencyWithdraw(address indexed user, uint indexed pid, uint amount);
    event SetRewardPerSecond(uint _pid, uint _gemsPerSecond);
    event StakeMagicat(address indexed user, uint indexed pid, uint indexed tokenID);
    event UnstakeMagicat(address indexed user, uint indexed pid, uint indexed tokenID);

    constructor(IERC20 _xboo, IERC721 _magicat) {
        xboo = _xboo;
        magicat = _magicat;
        isRewardToken[address(_xboo)] = true;
    }


    function poolLength() external view returns (uint) {
        return poolAmount;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint _from, uint _to, uint startTime, uint endTime) internal pure returns (uint) {
        _from = _from > startTime ? _from : startTime;
        if (_from > endTime || _to < startTime) {
            return 0;
        }
        if (_to > endTime) {
            return endTime - _from;
        }
        return _to - _from;
    }

    // View function to see pending BOOs on frontend.
    function pendingReward(uint _pid, address _user) external view returns (uint) {
        (uint xbooReward, uint magicatReward) = pendingRewards(_pid, _user);
        return xbooReward + magicatReward;
    }

    function pendingRewards(uint _pid, address _user) public view returns (uint xbooReward, uint magicatReward) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint accRewardPerShare = pool.accRewardPerShare;
        uint accRewardPerShareMagicat = pool.accRewardPerShareMagicat;

        if (block.timestamp > pool.lastRewardTime) {
            uint reward = pool.RewardPerSecond * getMultiplier(pool.lastRewardTime, block.timestamp, pool.startTime, pool.endTime);
            if(pool.xBooStakedAmount != 0) accRewardPerShare += reward * (10000 - magicatBoost) / 10000 * precisionOf[pool.TokenPrecision] / pool.xBooStakedAmount;
            if(pool.mpStakedAmount != 0) accRewardPerShareMagicat += reward * magicatBoost / 10000 * precisionOf[pool.TokenPrecision] / pool.mpStakedAmount;
        }
        xbooReward = (user.amount * accRewardPerShare / precisionOf[pool.TokenPrecision]) - user.rewardDebt;
        magicatReward = (effectiveMP(user.amount, user.mp) * accRewardPerShareMagicat / precisionOf[pool.TokenPrecision]) - user.catDebt;
        // magicatReward = (effectiveMP(user.amount) * accRewardPerShareMagicat / precisionOf[pool.TokenPrecision]) - user.catDebt;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint length = poolAmount;
        for (uint pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        uint reward = pool.RewardPerSecond * getMultiplier(pool.lastRewardTime, block.timestamp, pool.startTime, pool.endTime);

        if(pool.xBooStakedAmount != 0) pool.accRewardPerShare += reward * (10000 - magicatBoost) / 10000 * precisionOf[pool.TokenPrecision] / pool.xBooStakedAmount;
        if(pool.mpStakedAmount != 0) pool.accRewardPerShareMagicat += reward * magicatBoost / 10000 * precisionOf[pool.TokenPrecision] / pool.mpStakedAmount;
        pool.lastRewardTime = uint32(block.timestamp);
    }

    function userCurrentStakeableMP(uint _pid, address _user) public view returns (int) {
        return int(_stakeableMP(userInfo[_pid][_user].amount)) - int(userInfo[_pid][_user].mp);
    }

    function stakeableMP(uint _xboo) public view returns (uint) {
        return _stakeableMP(_xboo);
    }

    function stakeableMP(uint _pid, address _user) public view returns (uint) {
        return _stakeableMP(userInfo[_pid][_user].amount);
    }

    function effectiveMP(uint _amount, uint _mp) public view returns (uint) {
    // function effectiveMP(uint _amount) public view returns (uint) {
        _amount = _stakeableMP(_amount);
        return _mp < _amount ? _mp : _amount;
        // return _amount;
    }

    function _stakeableMP(uint _xboo) internal view returns (uint) {
        return mpPerXboo * _xboo / 1 ether;
    }

    function deposit(uint _pid, uint _amount) external nonReentrant {
        _deposit(_pid, _amount, msg.sender, new uint[](0));
    }

    function deposit(uint _pid, uint _amount, address to) external nonReentrant {
        _deposit(_pid, _amount, to, new uint[](0));
    }

    function deposit(uint _pid, uint _amount, uint[] memory tokenIDs) external nonReentrant {
        uint numberStaked = userInfo[_pid][msg.sender].mp;
        require(numberStaked == 0, "can only stake one nft");
        _deposit(_pid, _amount, msg.sender, tokenIDs);
    }

    function deposit(uint _pid, uint _amount, address to, uint[] memory tokenIDs) external nonReentrant {
        uint numberStaked = userInfo[_pid][to].mp;
        require(numberStaked == 0, "can only stake one nft");
        _deposit(_pid, _amount, to, tokenIDs);
    }

    // Deposit tokens.
    function _deposit(uint _pid, uint _amount, address to, uint[] memory tokenIDs) internal {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][to];

        // if(baseUserLimit > 0 && block.timestamp < pool.userLimitEndTime) {
        //     require(user.amount + _amount <= baseUserLimit, "deposit: user has hit deposit cap");
        // }

        updatePool(_pid);

        uint precision = precisionOf[pool.TokenPrecision];//precision
        uint amount = user.amount;

        uint pending = (amount * pool.accRewardPerShare / precision) - user.rewardDebt;
        uint pendingCat = effectiveMP(amount, user.mp) * pool.accRewardPerShareMagicat / precision - user.catDebt;
        // uint pendingCat = effectiveMP(amount) * pool.accRewardPerShareMagicat / precision - user.catDebt;

        user.amount += _amount;
        amount += _amount;
        pool.xBooStakedAmount += _amount;
        balanceOf[to] += _amount;

        user.rewardDebt = amount * pool.accRewardPerShare / precision;

        if(pending > 0)
            safeTransfer(pool.RewardToken, to, pending + pendingCat);
        if(_amount > 0)
            xboo.safeTransferFrom(msg.sender, address(this), _amount);


        emit Deposit(msg.sender, _pid, _amount);

        uint len = tokenIDs.length;
        if(len == 0) {
            user.catDebt = effectiveMP(amount, user.mp) * pool.accRewardPerShareMagicat / precision;
            // user.catDebt = effectiveMP(amount) * pool.accRewardPerShareMagicat / precision;
            return;
        }

        // pending = sumOfRarities(tokenIDs);
        pending = tokenIDs.length;
        stakedMagicatPower += pending;

        user.mp += pending;
        user.catDebt = effectiveMP(amount, user.mp) * pool.accRewardPerShareMagicat / precision;
        // user.catDebt = effectiveMP(amount) * pool.accRewardPerShareMagicat / precision;
        pool.mpStakedAmount += pending;

        do {
            unchecked {--len;}
            pending = tokenIDs[len];
            magicat.transferFrom(msg.sender, address(this), pending);
            _stakedMagicats[_pid][to].add(pending);
            emit StakeMagicat(to, _pid, pending);
        } while (len != 0);
    }

    // Withdraw tokens.
    function withdraw(uint _pid, uint _amount) external nonReentrant {
        _withdraw(_pid, _amount, msg.sender, new uint[](0));
    }

    function withdraw(uint _pid, uint _amount, address to) external nonReentrant {
        _withdraw(_pid, _amount, to, new uint[](0));
    }

    function withdraw(uint _pid, uint _amount, uint[] memory tokenIDs) external nonReentrant {
        _withdraw(_pid, _amount, msg.sender, tokenIDs);
    }

    function withdraw(uint _pid, uint _amount, address to, uint[] memory tokenIDs) external nonReentrant {
        _withdraw(_pid, _amount, to, tokenIDs);
    }

    function _withdraw(uint _pid, uint _amount, address to, uint[] memory tokenIDs) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);

        uint precision = precisionOf[pool.TokenPrecision];
        uint amount = user.amount;

        uint pending = (amount * pool.accRewardPerShare / precision) - user.rewardDebt;
        uint pendingCat = (effectiveMP(amount, user.mp) * pool.accRewardPerShareMagicat / precision) - user.catDebt;
        // uint pendingCat = (effectiveMP(amount) * pool.accRewardPerShareMagicat / precision) - user.catDebt;

        user.amount -= _amount;
        amount -= _amount;
        pool.xBooStakedAmount -= _amount;
        balanceOf[msg.sender] -= _amount;

        user.rewardDebt = amount * pool.accRewardPerShare / precision;

        if(pending > 0)
            safeTransfer(pool.RewardToken, to, pending + pendingCat);
        if(_amount > 0)
            safeTransfer(xboo, to, _amount);

        emit Withdraw(to, _pid, _amount);

        uint len = tokenIDs.length;
        if(len == 0) {
            user.catDebt = effectiveMP(amount, user.mp) * pool.accRewardPerShareMagicat / precision;
            // user.catDebt = effectiveMP(amount) * pool.accRewardPerShareMagicat / precision;
            return;
        }

        // pending = sumOfRarities(tokenIDs);
        pending = tokenIDs.length;
        stakedMagicatPower -= pending;

        user.mp -= pending;
        user.catDebt = effectiveMP(amount, user.mp) * pool.accRewardPerShareMagicat / precision;
        // user.catDebt = effectiveMP(amount) * pool.accRewardPerShareMagicat / precision;
        pool.mpStakedAmount -= pending;

        do {
            unchecked {--len;}
            pending = tokenIDs[len];
            require(_stakedMagicats[_pid][msg.sender].contains(pending), "Magicat not staked by this user in this pool!");
            _stakedMagicats[_pid][msg.sender].remove(pending);
            magicat.transferFrom(address(this), to, pending);
            emit UnstakeMagicat(msg.sender, _pid, pending);
        } while (len != 0);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint oldUserAmount = user.amount;
        pool.xBooStakedAmount -= user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        balanceOf[msg.sender] -= oldUserAmount;

        xboo.safeTransfer(address(msg.sender), oldUserAmount);
        emit EmergencyWithdraw(msg.sender, _pid, oldUserAmount);

    }

    // !! DO NOT CALL THIS UNLESS YOU KNOW EXACTLY WHAT YOU ARE DOING !!
    // Withdraw cats without caring about rewards. EMERGENCY ONLY.
    // !! DO NOT CALL THIS UNLESS YOU KNOW EXACTLY WHAT YOU ARE DOING !!
    // This will set your mp and catDebt to 0 even if you dont withdraw all cats. Make sure to emergency withdraw all your cats if you ever call this.
    // !! DO NOT CALL THIS UNLESS YOU KNOW EXACTLY WHAT YOU ARE DOING !!
    function emergencyCatWithdraw(uint _pid, uint[] calldata tokenIDs) external {
        require(emergencyCatWithdrawable);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // uint userMPs = sumOfRarities(tokenIDs);
        uint userMPs = tokenIDs.length;
        user.mp = 0;
        user.catDebt = 0;
        pool.mpStakedAmount -= userMPs;
        stakedMagicatPower -= userMPs;
        uint len = tokenIDs.length;
        do {
            unchecked {--len;}
            userMPs = tokenIDs[len];
            require(_stakedMagicats[_pid][msg.sender].contains(userMPs), "Magicat not staked by this user in this pool!");
            _stakedMagicats[_pid][msg.sender].remove(userMPs);
            magicat.transferFrom(address(this), msg.sender, userMPs);
            emit UnstakeMagicat(msg.sender, _pid, userMPs);
        } while (len != 0);
    }

    // Safe erc20 transfer function, just in case if rounding error causes pool to not have enough reward tokens.
    function safeTransfer(IERC20 token, address _to, uint _amount) internal {
        uint bal = token.balanceOf(address(this));
        if (_amount > bal) {
            token.safeTransfer(_to, bal);
        } else {
            token.safeTransfer(_to, _amount);
        }
    }

    function stakeAndUnstakeMagicats(uint _pid, uint[] memory stakeTokenIDs, uint[] memory unstakeTokenIDs) external nonReentrant {
        _withdraw(_pid, 0, msg.sender, unstakeTokenIDs);
        _deposit(_pid, 0, msg.sender, stakeTokenIDs);
    }

    function onERC721Received(address operator, address /*from*/, uint /*tokenId*/, bytes calldata /*data*/) external view returns (bytes4) {
        if(operator == address(this))
            return this.onERC721Received.selector;
        return 0;
    }

    // Admin functions

    function setEmergencyCatWithdrawable(bool allowed) external onlyAuth {
        emergencyCatWithdrawable = allowed;
    }

    function setCatMultiplier(uint mul) external onlyAdmin {
        mpPerXboo = mul;
    }

    function setMagicatBoost(uint32 boost) external onlyAdmin {
        require(boost < 5000); //5000 = 50%
        magicatBoost = boost;
    }

    function changeEndTime(uint _pid, uint32 addSeconds) external onlyAuth {
        poolInfo[_pid].endTime += addSeconds;
    }

    function stopReward(uint _pid) external onlyAuth {
        poolInfo[_pid].endTime = uint32(block.timestamp);
    }

    // function changePoolUserLimitEndTime(uint _pid, uint32 _time) external onlyAdmin {
    //     poolInfo[_pid].userLimitEndTime = _time;
    // }

    // function changeUserLimit(uint _limit) external onlyAdmin {
    //     baseUserLimit = _limit;
    // }

    // function changeBaseUserLimitTime(uint32 _time) external onlyAdmin {
    //     baseUserLimitTime = _time;
    // }

    function checkForToken(IERC20 _Token) private view {
        require(!isRewardToken[address(_Token)], "checkForToken: reward token or xboo provided");
    }

    function recoverWrongTokens(address _tokenAddress) external onlyAdmin {
        checkForToken(IERC20(_tokenAddress));

        uint bal = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), bal);

        emit AdminTokenRecovery(_tokenAddress, bal);
    }

    function emergencyRewardWithdraw(uint _pid, uint _amount) external onlyAdmin {
        poolInfo[_pid].RewardToken.safeTransfer(poolInfo[_pid].protocolOwnerAddress, _amount);
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(uint _rewardPerSecond, IERC20Ext _Token, uint32 _startTime, uint32 _endTime, address _protocolOwner) external onlyAuth {
        _add(_rewardPerSecond, _Token, _startTime, _endTime, _protocolOwner);
    }

    // Add a new token to the pool (internal).
    function _add(uint _rewardPerSecond, IERC20Ext _Token, uint32 _startTime, uint32 _endTime, address _protocolOwner) internal {
        require(_rewardPerSecond > 9, "AceLab _add: _rewardPerSecond needs to be at least 10 wei");

        checkForToken(_Token); // ensure you cant add duplicate pools
        isRewardToken[address(_Token)] = true;

        uint32 lastRewardTime = uint32(block.timestamp > _startTime ? block.timestamp : _startTime);
        uint8 decimalsRewardToken = uint8(_Token.decimals());
        require(decimalsRewardToken < 30, "Token has way too many decimals");
        if(precisionOf[decimalsRewardToken] == 0)
            precisionOf[decimalsRewardToken] = 10**(30 - decimalsRewardToken);

        PoolInfo storage poolinfo = poolInfo[poolAmount];
        poolinfo.RewardToken = _Token;
        poolinfo.RewardPerSecond = _rewardPerSecond;
        poolinfo.TokenPrecision = decimalsRewardToken;
        //poolinfo.xBooStakedAmount = 0;
        poolinfo.startTime = _startTime;
        poolinfo.endTime = _endTime;
        poolinfo.lastRewardTime = lastRewardTime;
        //poolinfo.accRewardPerShare = 0;
        poolinfo.protocolOwnerAddress = _protocolOwner;
        // poolinfo.userLimitEndTime = lastRewardTime + baseUserLimitTime;
        poolAmount += 1;
    }

    // Update the given pool's reward per second. Can only be called by the owner.
    function setRewardPerSecond(uint _pid, uint _rewardPerSecond) external onlyAdmin {

        updatePool(_pid);

        poolInfo[_pid].RewardPerSecond = _rewardPerSecond;

        emit SetRewardPerSecond(_pid, _rewardPerSecond);
    }

    /**
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function getStakedMagicats(uint _pid, address _user) external view returns (uint[] memory) {
        return _stakedMagicats[_pid][_user].values();
    }

}