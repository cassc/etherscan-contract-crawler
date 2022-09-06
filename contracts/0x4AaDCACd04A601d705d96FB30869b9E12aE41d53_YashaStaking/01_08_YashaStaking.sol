// SPDX-License-Identifier: MIT
/// @title YashaStaking Staking Contract
/// @author MrD 

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YashaStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct LockSetting {
        uint256 stakeMultiplier; // multiplier this setting gives to the bonus points (15 = 1.5x)
        uint256 lockDuration; // how long you need to lock for this setting in seconds
        uint256 totalLocked; // total number of tokens locked with this setting
    }

    struct UserLock {
        uint256 stakeMultiplier; // multiplier from the settings (15 = 1.5x)
        uint256 tokenAmount; // total amount they locked
        uint256 startTime; // start of the lock
        uint256 endTime; //when the lock ends
        uint256 lastHarvest; // block last harvested
    }

    struct Adjustment {
        uint256 blockNumber; // block the adjustment was made
        uint256 tokensPerBlock; // snapshot of the current token per/block
        uint256 nativePerBlock; // snapshot of the current native per/block
    }


    // aray of the different lock options
    LockSetting[] public lockSettings;

    // maping for the users locks
    // mapping(address => mapping( uint256 => UserLock)) public userLocks;
    mapping(address => UserLock[]) public userLocks;
    mapping(address => uint256) public userTotalLocks;

    // maping for the adjustments
    mapping(uint256 => Adjustment) public adjustments;
    uint256 public totalAdjustments;

    // Global active flag
    bool isActive;

    // max locks 1 account can ever have
    uint256 public constant maxLocks = 10;

    // The Tokens
    // token given as a reward
    IERC20 public rewardToken;

    // token that is staked
    IERC20 public stakeToken; 

    // distribution per block
    // amount per block for the rewardToken
    uint256 public tokensPerBlock; 

    // amount per block for ETH
    uint256 public nativePerBlock; 

    // The block number when rewards start 
    uint256 public startBlock;

    uint256 constant totalAllocPoint = 10000;

    event SetActive( bool isActive);
    event Deposit(address indexed user, uint256 indexed settingId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed settingId, uint256 amount);
    event Harvest(address indexed user, uint256 tokenAmount, uint256 ethAmount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 tokensPerBlock, uint256 nativePerBlock);
    event SetLockSettings(uint256[] locksMultiplier, uint256[] locksDuration);

    constructor(
        IERC20 _rewardToken,
        IERC20  _stakeToken,
        uint256 _tokensPerBlock,
        uint256 _nativePerBlock,
        uint256 _startBlock,
        uint256[] memory _locksMultiplier,
        uint256[] memory  _locksDuration
    ) {

        rewardToken = _rewardToken;
        stakeToken = _stakeToken;
        tokensPerBlock = _tokensPerBlock;
        nativePerBlock = _nativePerBlock;
        startBlock = _startBlock;

        _setLockSettings( _locksMultiplier , _locksDuration );
    }


    function setLockSettings(  uint256[] memory _locksMultiplier ,uint256[] memory  _locksDuration ) public onlyOwner {
        _setLockSettings( _locksMultiplier , _locksDuration );
    }

    function _setLockSettings( uint256[] memory _locksMultiplier ,uint256[] memory  _locksDuration ) private {
        delete lockSettings;
        for (uint256 i = 0; i < _locksMultiplier.length; ++i) {
            lockSettings.push(LockSetting({
                lockDuration : _locksDuration[i],
                stakeMultiplier : _locksMultiplier[i],
                totalLocked: 0
            }));
        }
        emit SetLockSettings(_locksMultiplier,_locksDuration);
    }

    /* @dev Return reward multiplier over the given _from to _to block */
    function _getMultiplier(uint256 _from, uint256 _to) private pure returns (uint256) {
        return _to - _from;
    }

    function _calc(uint256 _var, uint256 _mul, uint256 _div) private pure returns (uint256) {
        return (_var * _mul)/_div;
    }
    
    /* @dev View function to see pending rewards on frontend.*/
    function pendingRewards(uint256 _lockId, address _user)  external view returns (uint256,uint256) {
        return _pendingRewards(_lockId, _user);
    }

    /* @dev calc the pending rewards */
    function _pendingRewards(uint256 _lockId, address _user) internal view returns (uint256,uint256) {
        UserLock storage userLock = userLocks[_user][_lockId];

        uint256 stakedSupply = stakeToken.balanceOf(address(this));
        uint256 lastHarvest = userLock.lastHarvest;

        // if there are no adjustments or we have recently harvested, only get the current amount
        if(totalAdjustments == 0 || adjustments[totalAdjustments-1].blockNumber < lastHarvest) {
            return _calcRewardPeriod(userLock.tokenAmount, tokensPerBlock, nativePerBlock, userLock.stakeMultiplier, lastHarvest, stakedSupply, block.number);
        } else {

            // otherwise we break apart the rewards per adjustment block
            uint256 tokenAmount;
            uint256 nativeAmount;

            // get the current values first
            ( tokenAmount,  nativeAmount ) = _calcRewardPeriod(userLock.tokenAmount, tokensPerBlock, nativePerBlock, userLock.stakeMultiplier, adjustments[totalAdjustments-1].blockNumber, stakedSupply, block.number);

            for(uint256 i=totalAdjustments-1; i >= 0; --i){
                uint256 _tokenAmount;
                uint256 _nativeAmount;
                if(i == 0 || lastHarvest > adjustments[i-1].blockNumber){
                    (_tokenAmount, _nativeAmount ) = _calcRewardPeriod(userLock.tokenAmount, adjustments[i].tokensPerBlock, adjustments[i].nativePerBlock, userLock.stakeMultiplier, lastHarvest, stakedSupply, adjustments[i].blockNumber);
                    tokenAmount = tokenAmount + _tokenAmount;
                    nativeAmount = nativeAmount + _nativeAmount;
                    break;
                }

                ( _tokenAmount,  _nativeAmount ) = _calcRewardPeriod(userLock.tokenAmount, adjustments[i].tokensPerBlock, adjustments[i].nativePerBlock, userLock.stakeMultiplier, adjustments[i-1].blockNumber, stakedSupply, adjustments[i].blockNumber);
                tokenAmount = tokenAmount + _tokenAmount;
                nativeAmount = nativeAmount + _nativeAmount;

            }

            return (tokenAmount, nativeAmount);
        }
        
    }

    function _calcRewardPeriod(uint256 _tokenAmount, uint256 _tokensPerBlock, uint256 _nativePerBlock, uint256 _stakeMultiplier, uint256 _lastHarvest, uint256 _stakedSupply, uint256 _endBlock) private pure returns (uint256,uint256){


        uint256 tokenReward = _calc(_getMultiplier(_lastHarvest, _endBlock),_tokensPerBlock, totalAllocPoint); 
        uint256 nativeReward = _calc(_getMultiplier(_lastHarvest, _endBlock),_nativePerBlock, totalAllocPoint);
        
        uint256 _accTokensPerShare = _calc(tokenReward,1e12, _stakedSupply); 
        uint256 _accNativePerShare = _calc(nativeReward,1e12, _stakedSupply);

        uint256 _tokenMultiplier = _calc(_tokenAmount,_stakeMultiplier, totalAllocPoint)/10;

        return (
            _calc(_tokenMultiplier,_accTokensPerShare, 1e12),
            _calc(_tokenMultiplier,_accNativePerShare, 1e12)       
        );
    }   

    function harvest(uint256 _lockId) public nonReentrant {
        return _harvest(_lockId, msg.sender);

    }   

    function _harvest(uint256 _lockId, address _user) private {
       // UserLock storage userLock = userLocks[_user][_lockId];

        (uint256 pendingTokens, uint256 pendingNative) = _pendingRewards(_lockId, _user);

        if(pendingTokens > 0){
            safeTokenTransfer(_user, pendingTokens);
        }

        if(pendingNative > 0){
            (bool sent,) = address(_user).call{value: (pendingNative)}("");
            require(sent,"native harvest failed");
        }
        userLocks[_user][_lockId].lastHarvest = block.number;

        emit Harvest(_user, pendingTokens, pendingNative);

    }

    /* @dev deposit tokens into the pool */
    function deposit(uint256 _settingId, uint256 _amount) public nonReentrant {
        require(isActive,'Not active');
        require(userTotalLocks[msg.sender] < maxLocks, 'Max locks');
        require(_amount > 0 && stakeToken.balanceOf(address(msg.sender)) >= _amount, "Not enough tokens");

        LockSetting storage lockSetting = lockSettings[_settingId];

        stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        
        userLocks[msg.sender].push(UserLock({
            stakeMultiplier: lockSetting.stakeMultiplier,
            tokenAmount: _amount,
            startTime: block.timestamp,
            endTime: block.timestamp + lockSetting.lockDuration,
            lastHarvest:block.number
        }));

         userTotalLocks[msg.sender] = userLocks[msg.sender].length;
         
         lockSetting.totalLocked = lockSetting.totalLocked + _amount;
        emit Deposit(msg.sender, _settingId, _amount);
    }

    /* @dev withdraw unlocked tokens from the pool */
    function withdraw(uint256 _lockId) public nonReentrant {
        require(isActive,'Not active');

        UserLock storage userLock = userLocks[msg.sender][_lockId];

        require(userLock.tokenAmount > 0, "Nothing Staked");
        require(block.timestamp >= userLock.endTime, "Tokens Locked");

        (uint256 pendingToken, uint256 pendingNative) = _pendingRewards(_lockId, msg.sender);
        
        if (pendingToken > 0 || pendingNative > 0) {
            _harvest(_lockId,msg.sender);
        }

        
        // transfer to user 
        stakeToken.safeTransfer(address(msg.sender), userLock.tokenAmount);

        // keep things clean
        userLocks[msg.sender][_lockId] = userLocks[msg.sender][userLocks[msg.sender].length - 1];
        userLocks[msg.sender].pop();
        userTotalLocks[msg.sender] = userLocks[msg.sender].length;
        
        emit Withdraw(msg.sender, _lockId, userLock.tokenAmount);
    }

    function totalUserWeight(address _user) public view returns(uint256) {
        uint256 totalValue;
        
        for(uint256 i=0; i < userTotalLocks[_user]; ++i){
            totalValue = totalValue + ((userLocks[_user][i].tokenAmount * userLocks[_user][i].stakeMultiplier)/10);
        }

        return totalValue;
    }

    function totalUserStake(address _user) public view returns(uint256) {
        uint256 totalValue;
        
        for(uint256 i=0; i < userTotalLocks[_user]; ++i){
            totalValue = totalValue + userLocks[_user][i].tokenAmount;
        }

        return totalValue;
    }

    /* @dev Safe token transfer function, just in case if rounding error causes pool to not have enough tokens */
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 bal = rewardToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > bal) {
            transferSuccess = rewardToken.transfer(_to, bal);
        } else {
            transferSuccess = rewardToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
        emit SetActive(_isActive);
    }

    function updateRewardTokenContract(IERC20 _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }

    function updateStakeTokenContract(IERC20 _stakeToken) public onlyOwner {
        stakeToken = _stakeToken;
    }

    function updateEmissionRate(uint256 _tokensPerBlock, uint256 _nativePerBlock) public onlyOwner {
        adjustments[totalAdjustments] = Adjustment({
            blockNumber: block.number,
            tokensPerBlock: _tokensPerBlock,
            nativePerBlock: _nativePerBlock
        });

        totalAdjustments = totalAdjustments + 1;
        emit UpdateEmissionRate(msg.sender, _tokensPerBlock, _nativePerBlock);
    }

    // pull all the tokens out of the contract, needed for migrations/emergencies 
    function withdrawToken() public onlyOwner {
        safeTokenTransfer(address(owner()), rewardToken.balanceOf(address(this)));
    }

    // pull all the bnb out of the contract, needed for migrations/emergencies 
    function withdrawETH() public onlyOwner {
         (bool sent,) =address(owner()).call{value: (address(this).balance)}("");
        require(sent,"withdraw failed");
    }


    receive() external payable {}
}