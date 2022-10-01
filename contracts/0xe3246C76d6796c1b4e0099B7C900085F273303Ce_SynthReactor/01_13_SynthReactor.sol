// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/ISynthToken.sol";
import "../interfaces/IHelixToken.sol";
import "../interfaces/IHelixChefNFT.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Lock helixToken and earn synthToken. Longer lock durations and staking nfts increases rewards. 
contract SynthReactor is 
    Initializable,
    OwnableUpgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable
{
    struct User {
        uint256[] depositIndices;       // indices of all deposits opened by the user
        uint256 depositedHelix;         // sum of all unwithdrawn deposits
        uint256 weightedDeposits;       // sum of all unwithdrawn deposits modified by weight
        uint256 shares;                 // weightedDeposits modified by stakedNfts
        uint256 rewardDebt;             // used for calculating rewards
    }

    struct Deposit {
        address depositor;              // user making the deposit
        uint256 amount;                 // amount of deposited helix
        uint256 weight;                 // weight based on lock duration
        uint256 depositTimestamp;       // when the deposit was made
        uint256 unlockTimestamp;        // when the deposit can be unlocked
        bool withdrawn;                 // only true if the deposit has been withdrawn
    }
    
    struct LockModifier {
        uint256 duration;               // length of time a deposit will be locked (in seconds)
        uint256 weight;                 // modifies the reward based on the lock duration
    }

    /// Maps a user's address to a User
    mapping(address => User) public users;

    /// Maps depositIndices to a Deposit
    Deposit[] public deposits;

    /// Owner-curated list of valid deposit durations and associated weights
    LockModifier[] public lockModifiers;

    /// Token locked in the reactor
    address public helixToken;

    /// Token rewarded by the reactor
    address public synthToken;

    /// Contract the reactor references for stakedNfts
    address public nftChef;

    /// Last block that update was called
    uint256 public lastUpdateBlock;

    /// Used for calculating rewards
    uint256 public accTokenPerShare;
    uint256 private constant _REWARD_PRECISION = 1e19;
    uint256 private constant _WEIGHT_PRECISION = 100;
    
    /// Amount of synthToken to mint per block
    uint256 public synthToMintPerBlock;

    /// Sum of shares held by all users
    uint256 public totalShares;

    event Lock(
        address user, 
        uint256 depositId, 
        uint256 weight, 
        uint256 unlockTimestamp,
        uint256 depositedHelix,
        uint256 weightedDeposits,
        uint256 shares,
        uint256 totalShares
    );
    event Unlock(
        address user,
        uint256 depositIndex,
        uint256 depositedHelix,
        uint256 weightedDeposits,
        uint256 shares,
        uint256 totalShares
    );
    event UpdateUserStakedNfts(
        address user,
        uint256 stakedNfts,
        uint256 userShares,
        uint256 totalShares
    );
    event HarvestReward(address user, uint256 reward, uint256 rewardDebt);
    event UpdatePool(uint256 accTokenPerShare, uint256 lastUpdateBlock);
    event SetNftChef(address nftChef);
    event SetSynthToMintPerBlock(uint256 synthToMintPerBlock);
    event SetLockModifier(uint256 lockModifierIndex, uint256 duration, uint256 weight);
    event AddLockModifier(uint256 duration, uint256 weight, uint256 lockModifiersLength);
    event RemoveLockModifier(uint256 lockModifierIndex, uint256 lockModifiersLength);
    event EmergencyWithdrawErc20(address token, uint256 amount);

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "invalid address");
        _;
    }

    modifier onlyValidDepositIndex(uint256 _depositIndex) {
        require(_depositIndex < deposits.length, "invalid deposit index");
        _;
    }

    modifier onlyValidLockModifierIndex(uint256 lockModifierIndex) {
        require(lockModifierIndex < lockModifiers.length, "invalid lock modifier index");
        _;
    }

    modifier onlyValidDuration(uint256 _duration) {
        require(_duration > 0, "invalid duration");
        _;
    }

    modifier onlyValidWeight(uint256 _weight) {
        require(_weight > 0, "invalid weight");
        _;
    }

    modifier onlyValidAmount(uint256 _amount) {
        require(_amount > 0, "invalid amount");
        _;
    }

    modifier onlyNftChef() {
        require(msg.sender == nftChef, "caller is not nftChef");
        _;
    }

    function initialize(
        address _helixToken,
        address _synthToken,
        address _nftChef
    ) 
        external 
        initializer 
        onlyValidAddress(_helixToken)
        onlyValidAddress(_synthToken)
        onlyValidAddress(_nftChef)
    {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        helixToken = _helixToken;
        synthToken = _synthToken;
        nftChef = _nftChef;

        synthToMintPerBlock = 135 * 1e17;   // 13.5

        lastUpdateBlock = block.number;

        // default locked deposit durations and their weights
        lockModifiers.push(LockModifier(90 days, 5));
        lockModifiers.push(LockModifier(180 days, 10));
        lockModifiers.push(LockModifier(360 days, 30));
        lockModifiers.push(LockModifier(540 days, 50));
        lockModifiers.push(LockModifier(720 days, 100));
    }

    /// Create a new deposit and lock _amount of helixToken for _lockModifierIndex duration
    function lock(uint256 _amount, uint256 _lockModifierIndex) 
        external 
        whenNotPaused
        nonReentrant
        onlyValidAmount(_amount) 
        onlyValidLockModifierIndex(_lockModifierIndex) 
    {
        _harvestReward(msg.sender);

        User storage user = users[msg.sender];

        uint256 depositIndex = deposits.length;
        user.depositIndices.push(depositIndex);

        user.depositedHelix += _amount;

        uint256 weight = lockModifiers[_lockModifierIndex].weight;
        user.weightedDeposits += _getWeightedDepositIncrement(_amount, weight);

        uint256 stakedNfts = _getUserStakedNfts(msg.sender);
        uint256 prevShares = user.shares;
        uint256 shares = _getShares(user.weightedDeposits, stakedNfts);
        assert(shares >= prevShares);
        totalShares += shares - prevShares;
        user.shares = shares;
  
        uint256 unlockTimestamp = block.timestamp + lockModifiers[_lockModifierIndex].duration;
        deposits.push(
            Deposit({
                depositor: msg.sender, 
                amount: _amount,
                weight: weight,
                depositTimestamp: block.timestamp,
                unlockTimestamp: unlockTimestamp,
                withdrawn: false
            })
        );

        TransferHelper.safeTransferFrom(helixToken, msg.sender, address(this), _amount);

        emit Lock(
            msg.sender, 
            depositIndex, 
            weight,
            unlockTimestamp,
            user.depositedHelix, 
            user.weightedDeposits,
            user.shares,
            totalShares
        );
    }

    /// Unlock a deposit based on _depositIndex and return the caller's locked helixToken
    function unlock(uint256 _depositIndex) 
        external 
        whenNotPaused 
        nonReentrant 
        onlyValidDepositIndex(_depositIndex)
    {
        _harvestReward(msg.sender);

        Deposit storage deposit = deposits[_depositIndex];
        require(msg.sender == deposit.depositor, "caller is not depositor");
        require(block.timestamp >= deposit.unlockTimestamp, "deposit is locked");

        User storage user = users[msg.sender];
    
        uint256 amount = deposit.amount;
        user.depositedHelix -= amount;
        user.weightedDeposits -= _getWeightedDepositIncrement(amount, deposit.weight);

        uint256 stakedNfts = _getUserStakedNfts(msg.sender);
        uint256 prevShares = user.shares;
        uint256 shares = _getShares(user.weightedDeposits, stakedNfts);
        assert(prevShares >= shares);
        totalShares -= prevShares - shares;
        user.shares = shares;

        deposit.withdrawn = true;

        TransferHelper.safeTransfer(helixToken, msg.sender, amount);

        emit Unlock(
            msg.sender, 
            _depositIndex,
            user.depositedHelix,
            user.weightedDeposits,
            user.shares,
            totalShares
        );
    }

    /// Return the _user's pending synthToken reward
    function getPendingReward(address _user) 
        external
        view 
        onlyValidAddress(_user)
        returns (uint256)
    {
        uint256 _accTokenPerShare = accTokenPerShare;
        if (block.number > lastUpdateBlock) {
            _accTokenPerShare += _getAccTokenPerShareIncrement();
        }
        User memory user = users[_user];     
        uint256 toMint = user.shares * _accTokenPerShare / _REWARD_PRECISION;
        return toMint > user.rewardDebt ? toMint - user.rewardDebt : 0;
    }

    /// Update user and contract shares when the user stakes or unstakes nfts
    function updateUserStakedNfts(address _user, uint256 _stakedNfts) 
        external 
        onlyNftChef 
        nonReentrant
    {
        // Do nothing if the user has no open deposits
        if (users[_user].depositedHelix <= 0) {
            return;
        }

        _harvestReward(_user);

        User storage user = users[_user];
        uint256 prevShares = user.shares;
        uint256 shares = _getShares(user.weightedDeposits, _stakedNfts);
        if (shares >= prevShares) {
            // if the user has increased their stakedNfts
            totalShares += shares - prevShares;
        } else {
            // if the user has decreased their staked nfts
            totalShares -= prevShares - shares;
        }
        user.shares = shares;

        emit UpdateUserStakedNfts(_user, _stakedNfts, user.shares, totalShares);
    }

    /// Set the amount of synthToken to mint per block
    function setSynthToMintPerBlock(uint256 _synthToMintPerBlock) external onlyOwner {
        synthToMintPerBlock = _synthToMintPerBlock;
        emit SetSynthToMintPerBlock(_synthToMintPerBlock);
    }
    
    /// Set a lockModifierIndex's _duration and _weight pair
    function setLockModifier(uint256 _lockModifierIndex, uint256 _duration, uint256 _weight)
        external
        onlyOwner
        onlyValidLockModifierIndex(_lockModifierIndex)
        onlyValidDuration(_duration)
        onlyValidWeight(_weight)  
    {
        lockModifiers[_lockModifierIndex].duration = _duration;
        lockModifiers[_lockModifierIndex].weight = _weight;
        emit SetLockModifier(_lockModifierIndex, _duration, _weight);
    }
   
    /// Add a new _duration and _weight pair
    function addLockModifier(uint256 _duration, uint256 _weight) 
        external 
        onlyOwner
        onlyValidDuration(_duration) 
        onlyValidWeight(_weight)
    {
        lockModifiers.push(LockModifier(_duration, _weight));
        emit AddLockModifier(_duration, _weight, lockModifiers.length);
    }

    /// Remove an existing _duration and _weight pair by _lockModifierIndex
    function removeLockModifier(uint256 _lockModifierIndex) 
        external 
        onlyOwner
        onlyValidLockModifierIndex(_lockModifierIndex)
    {
        // remove by array shift to preserve order
        uint256 length = lockModifiers.length - 1;
        for (uint256 i = _lockModifierIndex; i < length; i++) {
            lockModifiers[i] = lockModifiers[i + 1];
        }
        lockModifiers.pop();
        emit RemoveLockModifier(_lockModifierIndex, lockModifiers.length);
    }

    /// Set the _nftChef contract that the reactor uses to get a user's stakedNfts
    function setNftChef(address _nftChef) external onlyOwner onlyValidAddress(_nftChef) {
        nftChef = _nftChef;
        emit SetNftChef(_nftChef);
    }

    /// Pause the reactor and prevent user interaction
    function pause() external onlyOwner {
        _pause();
    }

    /// Unpause the reactor and allow user interaction
    function unpause() external onlyOwner {
        _unpause();
    }

    /// Withdraw all the tokens in this contract. Emergency ONLY
    function emergencyWithdrawErc20(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        emit EmergencyWithdrawErc20(_token, amount); 
        TransferHelper.safeTransfer(_token, msg.sender, amount);
    }

    // Return the user's array of depositIndices
    function getUserDepositIndices(address _user) external view returns (uint[] memory) {
        return users[_user].depositIndices;
    }

    /// Return the length of the lockModifiers array
    function getLockModifiersLength() external view returns (uint256) {
        return lockModifiers.length;
    }

    /// Return the length of the deposits array
    function getDepositsLength() external view returns (uint256) {
        return deposits.length;
    }

    /// Harvest rewards accrued in synthToken by the caller's deposits
    function harvestReward() 
        external
    {
        _harvestReward(msg.sender);
    }

    /// Update the pool
    function updatePool() public {
        if (block.number <= lastUpdateBlock) {
            return;
        }

        accTokenPerShare += _getAccTokenPerShareIncrement();
        lastUpdateBlock = block.number;
        emit UpdatePool(accTokenPerShare, lastUpdateBlock);
    }

    // Harvest rewards accrued in synthToken by the _caller's deposits
    function _harvestReward(address _caller) private {
        if (paused()) {
            return;
        }

        updatePool();

        User storage user = users[_caller];

        uint256 reward = user.shares * accTokenPerShare / _REWARD_PRECISION;
        uint256 toMint = reward > user.rewardDebt ? reward - user.rewardDebt : 0;
        user.rewardDebt = reward;

        emit HarvestReward(_caller, toMint, user.rewardDebt);
        if (toMint > 0) {
            bool success = ISynthToken(synthToken).mint(_caller, toMint);
            require(success, "harvest reward failed");
        }
    }

    // Return the _user's stakedNfts
    function _getUserStakedNfts(address _user) private view returns (uint256) {
        return IHelixChefNFT(nftChef).getUserStakedNfts(_user); 
    }

    // Return the amount to increment the accTokenPerShare by
    function _getAccTokenPerShareIncrement() private view returns (uint256) {
        if (totalShares == 0) {
            return 0;
        }
        uint256 blockDelta = block.number - lastUpdateBlock;
        return blockDelta * synthToMintPerBlock * _REWARD_PRECISION / totalShares;
    }

    // Return the deposit _amount weighted by _weight
    function _getWeightedDepositIncrement(uint256 _amount, uint256 _weight) 
        private 
        pure 
        returns (uint256) 
    {
        return _amount * (_WEIGHT_PRECISION + _weight) / _WEIGHT_PRECISION;
    }

    // Return the shares held by a user with _weightedDeposit and _stakedNfts
    function _getShares(uint256 _weightedDeposit, uint256 _stakedNfts) private pure returns (uint256) {   
        if (_stakedNfts <= 0) {
            return _weightedDeposit;
        }
        if (_stakedNfts <= 2) {
            return _weightedDeposit * 15 / 10;
        }
        else {
            return _weightedDeposit * 2;
        }
    }
}