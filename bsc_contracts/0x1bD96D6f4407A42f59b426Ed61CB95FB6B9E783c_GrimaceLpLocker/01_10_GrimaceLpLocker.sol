// SPDX-License-Identifier: UNLICENSED

// This contract locks uniswap v2 liquidity tokens. Used to give investors peace of mind a token team has locked liquidity
// and that the univ2 tokens cannot be removed from uniswap until the specified unlock date has been reached.

pragma solidity 0.8.17;

import "./TransferHelper.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract GrimaceLpLocker is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    IUniswapV2Factory public uniswapFactory;

    struct UserInfo {
        EnumerableSet.AddressSet lockedTokens; // records all tokens the user has locked
        mapping(address => uint256[]) locksForToken; // map erc20 address to lock id for that token
    }

    struct TokenLock {
        uint256 lockDate; // the date the token was locked
        uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
        uint256 initialAmount; // the initial lock amount
        uint256 unlockDate; // the date the token can be withdrawn
        uint256 lockID; // lockID nonce per uni pair
        address owner;
        bool paidInBnb; // Whether lock fee was paid in bnb
    }

    mapping(address => UserInfo) private users;

    EnumerableSet.AddressSet private lockedTokens;
    mapping(address => TokenLock[]) public tokenLocks; //map univ2 pair to all its locks

    uint256 feePercentageBase = 100_000; // 10% is 10_000 | 1% is 1_000
    struct FeeStruct {
        uint256 bnbFee; // Small bnb fee to prevent spam on the platform
        uint256 lpFeePercentage; // Percentage of locked LP fee
    }
    FeeStruct public fees;
    
    address payable feeReceiver;
    address payable devAddress;

    event onDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
    event onWithdraw(address lpToken, uint256 amount);

    constructor(
        IUniswapV2Factory _uniswapFactory,
        address _feeReceiver,
        address _devAddress,
        uint256 _bnbFee,
        uint256 _lpFeePercentage
    ) {
        feeReceiver = payable(_feeReceiver);
        devAddress = payable(_devAddress);
        fees.bnbFee = _bnbFee;
        fees.lpFeePercentage = _lpFeePercentage;
        uniswapFactory = _uniswapFactory;
    }
    
    function setFeeRecipient(address payable _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setDevAddress(address payable _devAddress) external onlyOwner {
        devAddress = _devAddress;
    }
    
    function setBnbFee(uint256 _bnbFee) external onlyOwner {
        fees.bnbFee = _bnbFee;
    }

    function setLpFeePercentage(uint256 _lpFeePercentage) external onlyOwner {
        fees.lpFeePercentage = _lpFeePercentage;
    }

    /**
    * @notice Creates a new lock
    * @param _lpToken the univ2 token address
    * @param _amount amount of LP tokens to lock
    * @param _unlock_date the unix timestamp (in seconds) until unlock   
    * @param _fee_in_bnb fees can be paid in bnb or in a secondary token such as UNCX with a discount on univ2 tokens
    * @param _withdrawer the user who can withdraw liquidity once the lock expires.
    */
    function lockLPToken (
        address _lpToken, 
        uint256 _amount, 
        uint256 _unlock_date, 
        bool _fee_in_bnb, 
        address payable _withdrawer
    ) external payable nonReentrant {
        require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
        require(_amount > 0, 'INSUFFICIENT');

        // ensure this pair is a univ2 pair by querying the factory
        IUniswapV2Pair lpair = IUniswapV2Pair(address(_lpToken));
        address factoryPairAddress = uniswapFactory.getPair(lpair.token0(), lpair.token1());
        require(factoryPairAddress == address(_lpToken), 'NOT UNIV2');

        // Collect LP tokens
        TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);
        uint256 amountLocked = _amount;

        // Execute fees
        if (_fee_in_bnb) { // charge fee in bnb
            uint256 bnbFee = fees.bnbFee;
            require(msg.value == bnbFee, 'FEE NOT MET');

            uint256 devShare = bnbFee;
            devAddress.transfer(devShare);
        } else { // charge fee in lp token
            uint256 lpFee = amountLocked * fees.lpFeePercentage / feePercentageBase;
            uint256 feeReceiverShare = lpFee;

            TransferHelper.safeTransfer(_lpToken, feeReceiver, feeReceiverShare);
            amountLocked -= lpFee;
        }

        // Register lock
        TokenLock memory token_lock;
        token_lock.lockDate = block.timestamp;
        token_lock.amount = amountLocked;
        token_lock.initialAmount = amountLocked;
        token_lock.unlockDate = _unlock_date;
        token_lock.lockID = tokenLocks[_lpToken].length;
        token_lock.owner = _withdrawer;
        token_lock.paidInBnb = _fee_in_bnb;

        // record the lock for the univ2pair
        tokenLocks[_lpToken].push(token_lock);
        lockedTokens.add(_lpToken);

        // record the lock for the user
        UserInfo storage user = users[_withdrawer];
        user.lockedTokens.add(_lpToken);
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(token_lock.lockID);
        
        emit onDeposit(_lpToken, msg.sender, token_lock.amount, token_lock.lockDate, token_lock.unlockDate);
    }
    
    /**
    * @notice extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed
    * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
    */
    function relock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _unlock_date) external nonReentrant {
        require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
        require(userLock.unlockDate < _unlock_date, 'UNLOCK BEFORE');
        
        userLock.unlockDate = _unlock_date;
    }
    
    /**
    * @notice withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
    * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
    */
    function withdraw (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
        require(_amount > 0, 'ZERO WITHDRAWL');
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
        require(userLock.unlockDate < block.timestamp, 'NOT YET');
        userLock.amount = userLock.amount - _amount;
        
        // clean user storage
        if (userLock.amount == 0) {
            uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
            userLocks[_index] = userLocks[userLocks.length-1];
            userLocks.pop();
            if (userLocks.length == 0) {
                users[msg.sender].lockedTokens.remove(_lpToken);
            }
        }
        
        TransferHelper.safeTransfer(_lpToken, msg.sender, _amount);
        emit onWithdraw(_lpToken, _amount);
    }
    
    /**
    * @notice increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees, and faster loading on our live block explorer
    */
    function incrementLock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount, bool _fee_in_bnb) external payable nonReentrant {
        require(_amount > 0, 'ZERO AMOUNT');
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
        
        TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);
        uint256 amountLocked = _amount;

        // Execute fees
        if (_fee_in_bnb) { // charge fee in bnb
            uint256 bnbFee = fees.bnbFee;
            require(msg.value == bnbFee, 'FEE NOT MET');

            uint256 devShare = bnbFee;
            uint256 feeReceiverShare = bnbFee - devShare;
            feeReceiver.transfer(feeReceiverShare);
            devAddress.transfer(devShare);
        } else { // charge fee in lp token
            uint256 lpFee = amountLocked * fees.lpFeePercentage / feePercentageBase;
            uint256 feeReceiverShare = lpFee;

            TransferHelper.safeTransfer(_lpToken, feeReceiver, feeReceiverShare);
            amountLocked -= lpFee;
        }
        
        userLock.amount = userLock.amount + amountLocked;
        if (userLock.paidInBnb && !_fee_in_bnb)
            userLock.paidInBnb = false;
        
        emit onDeposit(_lpToken, msg.sender, amountLocked, userLock.lockDate, userLock.unlockDate);
    }
    
    /**
    * @notice transfer a lock to a new owner, e.g. presale project -> project owner
    */
    function transferLockOwnership (address _lpToken, uint256 _index, uint256 _lockID, address payable _newOwner) external {
        require(msg.sender != _newOwner, 'OWNER');
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage transferredLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && transferredLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
        
        // record the lock for the new Owner
        UserInfo storage user = users[_newOwner];
        user.lockedTokens.add(_lpToken);
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(transferredLock.lockID);
        
        // remove the lock from the old owner
        uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
        userLocks[_index] = userLocks[userLocks.length-1];
        userLocks.pop();
        if (userLocks.length == 0) {
            users[msg.sender].lockedTokens.remove(_lpToken);
        }
        transferredLock.owner = _newOwner;
    }    
    
    function getNumLocksForToken (address _lpToken) external view returns (uint256) {
        return tokenLocks[_lpToken].length;
    }
    
    function getNumLockedTokens () external view returns (uint256) {
        return lockedTokens.length();
    }
    
    function getLockedTokenAtIndex (uint256 _index) external view returns (address) {
        return lockedTokens.at(_index);
    }
    
    // user functions
    function getUserNumLockedTokens (address _user) external view returns (uint256) {
        UserInfo storage user = users[_user];
        return user.lockedTokens.length();
    }
    
    function getUserLockedTokenAtIndex (address _user, uint256 _index) external view returns (address) {
        UserInfo storage user = users[_user];
        return user.lockedTokens.at(_index);
    }
    
    function getUserNumLocksForToken (address _user, address _lpToken) external view returns (uint256) {
        UserInfo storage user = users[_user];
        return user.locksForToken[_lpToken].length;
    }
    
    function getUserLockForTokenAtIndex (address _user, address _lpToken, uint256 _index) external view 
    returns (uint256, uint256, uint256, uint256, uint256, address) {
        uint256 lockID = users[_user].locksForToken[_lpToken][_index];
        TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
        return (tokenLock.lockDate, tokenLock.amount, tokenLock.initialAmount, tokenLock.unlockDate, tokenLock.lockID, tokenLock.owner);
    }
}