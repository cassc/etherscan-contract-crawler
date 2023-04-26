/**
 * This contract locks uniswap v2 liquidity tokens.
 * Used to give investors peace of mind a token team has locked liquidity
 * and that the univ2 tokens cannot be removed from uniswap until the specified unlock date has been reached.
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

interface IERCTransfer {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IMigrator {
    function migrate(address lpToken, uint256 amount, uint256 unlockDate, address owner)
        external
        returns (bool);
}

contract UniswapV2Locker is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    IUniswapV2Factory public uniswapFactory;

    struct UserInfo {
        EnumerableSet.AddressSet _lockedTokens; // records all tokens the user has locked
        mapping(address => uint256[]) locksForToken; // map erc20 address to lock id for that token
    }

    struct TokenLock {
        uint256 lockDate; // the date the token was locked
        uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
        uint256 initialAmount; // the initial lock amount
        uint256 unlockDate; // the date the token can be withdrawn
        uint256 lockID; // lockID nonce per uni pair
        address owner;
        string lockName;
    }

    mapping(address => UserInfo) private _users;

    EnumerableSet.AddressSet private _lockedTokens;
    mapping(address => TokenLock[]) public tokenLocks; // map univ2 pair to all its locks

    struct FeeStruct {
        uint256 ethFee; // small eth fee to prevent spam on the platform
        IERCTransfer secondaryFeeToken; // secondary token to use as fee for locking
        uint256 secondaryTokenFee; // flat rate fee for locking and paying w/ secondary token
        uint256 secondaryTokenDiscount; // discount on liquidity fee for burning secondaryToken
        uint256 liquidityFee; // fee on univ2 liquidity tokens
        uint256 referralPercent; // fee for referrals
        IERCTransfer referralToken; // token the refferer must hold to qualify as a referrer
        uint256 referralHold; // balance the referrer must hold to qualify as a referrer
        uint256 referralDiscount; // discount on flatrate fees for using a valid referral address
    }

    FeeStruct public gFees;
    EnumerableSet.AddressSet private _feeWhitelist;

    address payable public devaddr;

    IMigrator public migrator;

    event OnDeposit(
        address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate
    );
    event OnWithdraw(address lpToken, uint256 amount);

    constructor(IUniswapV2Factory _uniswapFactory) {
        devaddr = payable(msg.sender);
        gFees.referralPercent = 250; // 25%
        gFees.ethFee = 0.01 ether;
        gFees.secondaryTokenFee = 1000e18; // may be adjusted to account for price later
        gFees.secondaryTokenDiscount = 200; // 20%
        gFees.liquidityFee = 10; // 1%
        gFees.referralHold = 10e18; // 10 WORM
        gFees.referralDiscount = 100; // 10%
        uniswapFactory = _uniswapFactory;
    }

    receive() external payable {}

    function setDev(address payable _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    /**
     * @notice set the migrator contract which allows locked lp tokens to be migrated to uniswap v3
     */
    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function setSecondaryFeeToken(address _secondaryFeeToken) public onlyOwner {
        gFees.secondaryFeeToken = IERCTransfer(_secondaryFeeToken);
    }

    /**
     * @notice referrers need to hold the specified token and hold amount to be elegible for referral fees
     */
    function setReferralTokenAndHold(IERCTransfer _referralToken, uint256 _hold) public onlyOwner {
        gFees.referralToken = _referralToken;
        gFees.referralHold = _hold;
    }

    function setFees(
        uint256 _referralPercent,
        uint256 _referralDiscount,
        uint256 _ethFee,
        uint256 _secondaryTokenFee,
        uint256 _secondaryTokenDiscount,
        uint256 _liquidityFee
    ) public onlyOwner {
        gFees.referralPercent = _referralPercent;
        gFees.referralDiscount = _referralDiscount;
        gFees.ethFee = _ethFee;
        gFees.secondaryTokenFee = _secondaryTokenFee;
        gFees.secondaryTokenDiscount = _secondaryTokenDiscount;
        gFees.liquidityFee = _liquidityFee;
    }

    /**
     * @notice whitelisted accounts dont pay flatrate fees on locking
     */
    function whitelistFeeAccount(address _user, bool _add) public onlyOwner {
        if (_add) {
            _feeWhitelist.add(_user);
        } else {
            _feeWhitelist.remove(_user);
        }
    }

    /**
     * @notice Creates a new lock
     * @param _lpToken the univ2 token address
     * @param _amount amount of LP tokens to lock
     * @param _unlockDate the unix timestamp (in seconds) until unlock
     * @param _referral the referrer address if any or address(0) for none
     * @param _feeInEth fees can be paid in eth or in a secondary token such as $WORM with a discount on univ2 tokens
     * @param _withdrawer the user who can withdraw liquidity once the lock expires.
     * @param _lockName a name for the lock, used for display purposes only
     */
    function lockLPToken(
        address _lpToken,
        uint256 _amount,
        uint256 _unlockDate,
        address payable _referral,
        bool _feeInEth,
        address payable _withdrawer,
        string memory _lockName
    ) external payable nonReentrant {
        // prevents errors when timestamp entered in milliseconds
        require(_unlockDate < 10_000_000_000, "TIMESTAMP INVALID");
        require(_amount > 0, "INSUFFICIENT");

        // ensure this pair is a univ2 pair by querying the factory
        IUniswapV2Pair lpair = IUniswapV2Pair(_lpToken);

        address factoryPairAddress = uniswapFactory.getPair(lpair.token0(), lpair.token1());

        require(factoryPairAddress == address(_lpToken), "NOT UNIV2");

        TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);

        if (_referral != address(0) && address(gFees.referralToken) != address(0)) {
            require(
                gFees.referralToken.balanceOf(_referral) >= gFees.referralHold, "INADEQUATE BALANCE"
            );
        }

        // flatrate fees
        if (!_feeWhitelist.contains(msg.sender)) {
            if (_feeInEth) {
                // charge fee in eth
                uint256 ethFee = gFees.ethFee;
                if (_referral != address(0)) {
                    ethFee = ethFee * (1000 - gFees.referralDiscount) / 1000;
                }
                require(msg.value == ethFee, "FEE NOT MET");
                uint256 devFee = ethFee;
                if (ethFee != 0 && _referral != address(0)) {
                    // referral fee
                    uint256 referralFee = devFee * gFees.referralPercent / 1000;
                    _referral.transfer(referralFee);
                    devFee = devFee - referralFee;
                }
                devaddr.transfer(devFee);
            } else {
                // charge fee in token
                uint256 tokenFee = gFees.secondaryTokenFee;
                if (_referral != address(0)) {
                    tokenFee = tokenFee * (1000 - gFees.referralDiscount) / 1000;
                }
                TransferHelper.safeTransferFrom(
                    address(gFees.secondaryFeeToken), address(msg.sender), address(this), tokenFee
                );
                if (gFees.referralPercent != 0 && _referral != address(0)) {
                    uint256 referralFee = tokenFee * gFees.referralPercent / 1000;
                    TransferHelper.safeApprove(
                        address(gFees.secondaryFeeToken), _referral, referralFee
                    );
                    TransferHelper.safeTransfer(
                        address(gFees.secondaryFeeToken), _referral, referralFee
                    );
                    tokenFee = tokenFee - referralFee;
                }
                uint256 tokenFeeHeld = gFees.secondaryFeeToken.balanceOf(address(this));
                gFees.secondaryFeeToken.transfer(devaddr, tokenFeeHeld);
            }
        } else if (msg.value > 0) {
            // refund eth if a whitelisted member sent it by mistake
            payable(msg.sender).transfer(msg.value);
        }

        // percent fee
        uint256 liquidityFee = _amount * gFees.liquidityFee / 1000;
        if (!_feeInEth && !_feeWhitelist.contains(msg.sender)) {
            // fee discount for large lockers using secondary token
            liquidityFee = liquidityFee * (1000 - gFees.secondaryTokenDiscount) / 1000;
        }
        TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
        uint256 amountLocked = _amount - liquidityFee;

        TokenLock memory _tokenLock;
        _tokenLock.lockDate = block.timestamp;
        _tokenLock.amount = amountLocked;
        _tokenLock.initialAmount = amountLocked;
        _tokenLock.unlockDate = _unlockDate;
        _tokenLock.lockID = tokenLocks[_lpToken].length;
        _tokenLock.owner = _withdrawer;
        _tokenLock.lockName = _lockName;

        // record the lock for the univ2pair
        tokenLocks[_lpToken].push(_tokenLock);
        _lockedTokens.add(_lpToken);

        // record the lock for the user
        UserInfo storage user = _users[_withdrawer];
        user._lockedTokens.add(_lpToken);
        uint256[] storage _userLocks = user.locksForToken[_lpToken];
        _userLocks.push(_tokenLock.lockID);

        emit OnDeposit(
            _lpToken, msg.sender, _tokenLock.amount, _tokenLock.lockDate, _tokenLock.unlockDate
        );
    }

    /**
     * @notice extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed
     * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
     */
    function relock(address _lpToken, uint256 _index, uint256 _lockID, uint256 _unlockDate)
        external
        nonReentrant
    {
        // prevents errors when timestamp entered in milliseconds
        require(_unlockDate < 10_000_000_000, "TIMESTAMP INVALID");
        uint256 lockID = _users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, "LOCK MISMATCH"); // ensures correct lock is affected
        require(userLock.unlockDate < _unlockDate, "UNLOCK BEFORE");

        userLock.unlockDate = _unlockDate;
    }

    /**
     * @notice withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
     * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
     */
    function withdraw(address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount)
        external
        nonReentrant
    {
        require(_amount > 0, "ZERO WITHDRAWL");
        uint256 lockID = _users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, "LOCK MISMATCH"); // ensures correct lock is affected
        require(userLock.unlockDate < block.timestamp, "NOT YET");
        userLock.amount = userLock.amount - _amount;

        // clean user storage
        if (userLock.amount == 0) {
            uint256[] storage userLocks = _users[msg.sender].locksForToken[_lpToken];
            userLocks[_index] = userLocks[userLocks.length - 1];
            userLocks.pop();
            if (userLocks.length == 0) {
                _users[msg.sender]._lockedTokens.remove(_lpToken);
            }
        }

        TransferHelper.safeTransfer(_lpToken, msg.sender, _amount);
        emit OnWithdraw(_lpToken, _amount);
    }

    /**
     * @notice increase the amount of tokens per a specific lock,
     * this is preferable to creating a new lock, less fees, and faster loading on our live block explorer
     */
    function incrementLock(address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount)
        external
        nonReentrant
    {
        require(_amount > 0, "ZERO AMOUNT");
        uint256 lockID = _users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, "LOCK MISMATCH"); // ensures correct lock is affected

        TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);

        // send univ2 fee to dev address
        uint256 liquidityFee = _amount * gFees.liquidityFee / 1000;
        TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
        uint256 amountLocked = _amount - liquidityFee;

        userLock.amount = userLock.amount + amountLocked;

        emit OnDeposit(_lpToken, msg.sender, amountLocked, userLock.lockDate, userLock.unlockDate);
    }

    /**
     * @notice split a lock into two seperate locks,
     * useful when a lock is about to expire and youd like to relock a portion
     * and withdraw a smaller portion. Or split into multiple locks over time.
     */
    function splitLock(address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount)
        external
        payable
        nonReentrant
    {
        require(_amount > 0, "ZERO AMOUNT");
        uint256 lockID = _users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, "LOCK MISMATCH"); // ensures correct lock is affected

        require(msg.value == gFees.ethFee, "FEE NOT MET");
        devaddr.transfer(gFees.ethFee);

        userLock.amount = userLock.amount - _amount;

        TokenLock memory _tokenLock;
        _tokenLock.lockDate = userLock.lockDate;
        _tokenLock.amount = _amount;
        _tokenLock.initialAmount = _amount;
        _tokenLock.unlockDate = userLock.unlockDate;
        _tokenLock.lockID = tokenLocks[_lpToken].length;
        _tokenLock.owner = msg.sender;

        // record the lock for the univ2pair
        tokenLocks[_lpToken].push(_tokenLock);

        // record the lock for the user
        UserInfo storage user = _users[msg.sender];
        uint256[] storage _userLocks = user.locksForToken[_lpToken];
        _userLocks.push(_tokenLock.lockID);
    }

    /**
     * @notice transfer a lock to a new owner, e.g. presale project -> project owner
     */
    function transferLockOwnership(
        address _lpToken,
        uint256 _index,
        uint256 _lockID,
        address payable _newOwner
    ) external {
        require(msg.sender != _newOwner, "OWNER");
        uint256 lockID = _users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage transferredLock = tokenLocks[_lpToken][lockID];
        // ensures correct lock is affected
        require(lockID == _lockID && transferredLock.owner == msg.sender, "LOCK MISMATCH");

        // record the lock for the new Owner
        UserInfo storage user = _users[_newOwner];
        user._lockedTokens.add(_lpToken);
        uint256[] storage _userLocks = user.locksForToken[_lpToken];
        _userLocks.push(transferredLock.lockID);

        // remove the lock from the old owner
        uint256[] storage userLocks = _users[msg.sender].locksForToken[_lpToken];
        userLocks[_index] = userLocks[userLocks.length - 1];
        userLocks.pop();
        if (userLocks.length == 0) {
            _users[msg.sender]._lockedTokens.remove(_lpToken);
        }
        transferredLock.owner = _newOwner;
    }

    /**
     * @notice migrates liquidity to uniswap v3
     */
    function migrate(address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount)
        external
        nonReentrant
    {
        require(address(migrator) != address(0), "NOT SET");
        require(_amount > 0, "ZERO MIGRATION");

        uint256 lockID = _users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(lockID == _lockID && userLock.owner == msg.sender, "LOCK MISMATCH"); // ensures correct lock is affected
        userLock.amount = userLock.amount - _amount;

        // clean user storage
        if (userLock.amount == 0) {
            uint256[] storage userLocks = _users[msg.sender].locksForToken[_lpToken];
            userLocks[_index] = userLocks[userLocks.length - 1];
            userLocks.pop();
            if (userLocks.length == 0) {
                _users[msg.sender]._lockedTokens.remove(_lpToken);
            }
        }

        TransferHelper.safeApprove(_lpToken, address(migrator), _amount);
        migrator.migrate(_lpToken, _amount, userLock.unlockDate, msg.sender);
    }

    function getNumLocksForToken(address _lpToken) external view returns (uint256) {
        return tokenLocks[_lpToken].length;
    }

    function getNumLockedTokens() external view returns (uint256) {
        return _lockedTokens.length();
    }

    function getLockedTokenAtIndex(uint256 _index) external view returns (address) {
        return _lockedTokens.at(_index);
    }

    // user functions
    function getUserNumLockedTokens(address _user) external view returns (uint256) {
        UserInfo storage user = _users[_user];
        return user._lockedTokens.length();
    }

    function getUserLockedTokenAtIndex(address _user, uint256 _index)
        external
        view
        returns (address)
    {
        UserInfo storage user = _users[_user];
        return user._lockedTokens.at(_index);
    }

    function getUserNumLocksForToken(address _user, address _lpToken)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = _users[_user];
        return user.locksForToken[_lpToken].length;
    }

    function getUserLockForTokenAtIndex(address _user, address _lpToken, uint256 _index)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, address, string memory)
    {
        uint256 lockID = _users[_user].locksForToken[_lpToken][_index];
        TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
        return (
            tokenLock.lockDate,
            tokenLock.amount,
            tokenLock.initialAmount,
            tokenLock.unlockDate,
            tokenLock.lockID,
            tokenLock.owner,
            tokenLock.lockName
        );
    }

    function getLockForTokenAtIndex(address _lpToken, uint256 _index)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, address, string memory)
    {
        TokenLock storage tokenLock = tokenLocks[_lpToken][_index];
        return (
            tokenLock.lockDate,
            tokenLock.amount,
            tokenLock.initialAmount,
            tokenLock.unlockDate,
            tokenLock.lockID,
            tokenLock.owner,
            tokenLock.lockName
        );
    }

    // whitelist
    function getWhitelistedUsersLength() external view returns (uint256) {
        return _feeWhitelist.length();
    }

    function getWhitelistedUserAtIndex(uint256 _index) external view returns (address) {
        return _feeWhitelist.at(_index);
    }

    function getUserWhitelistStatus(address _user) external view returns (bool) {
        return _feeWhitelist.contains(_user);
    }
}