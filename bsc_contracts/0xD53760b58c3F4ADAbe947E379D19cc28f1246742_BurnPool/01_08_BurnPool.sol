// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Olive.cash, Pancakeswap
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//import "hardhat/console.sol";

contract BurnPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The timestamp when REWARD mining ends.
    uint256 public timestampEnd;

    // The timestamp when REWARD mining starts.
    uint256 public timestampStart;

    // The timestamp of the last pool update
    uint256 public timestampLast;

    // REWARD tokens created per second.
    uint256 public rewardPerSecond;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The reward token
    IERC20 public rewardToken;

    // The staked token
    IERC20 public stakedToken;

    //Total shares
    uint256 public totalShares;

    uint256 public boostBps = 50000;

    uint256 public claimSanityLimit = 5000 ether;

    mapping(address => bool) public isBoostEligible;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 shares; // How many shares in the pool the user owns
        uint256 rewardDebt; // Reward debt
    }

    function initialize(
        IERC20 _stakedToken,
        IERC20 _rewardToken,
        uint256 _rewardsWad,
        uint256 _timestampStart,
        uint256 _durationSeconds,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        isInitialized = true;
        PRECISION_FACTOR = uint256(
            10 **
                (uint256(30) -
                    (IERC20Metadata(address(_rewardToken)).decimals()))
        );

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        _rewardToken.transferFrom(msg.sender, address(this), _rewardsWad);

        burnpoolSetStartAndDuration(_timestampStart, _durationSeconds);

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) public {
        depositFor(_amount, msg.sender);
    }

    function depositFor(uint256 _amount, address _for) public nonReentrant {
        UserInfo storage user = userInfo[_for];

        _updatePool();

        if (user.shares > 0) {
            uint256 pending = (user.shares * accTokenPerShare) /
                PRECISION_FACTOR -
                user.rewardDebt;
            if (pending > 0) {
                rewardToken.safeTransfer(_for, pending);
            }
        }

        if (_amount > 0) {
            uint256 newShares = isBoostEligible[_for]
                ? (_amount * boostBps) / 10000
                : _amount;
            user.shares += newShares;
            totalShares += newShares;
            stakedToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
        }

        user.rewardDebt = (user.shares * accTokenPerShare) / PRECISION_FACTOR;
    }

    /*
     * @notice Claim staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function claim() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        uint256 pending = (user.shares * accTokenPerShare) /
            PRECISION_FACTOR -
            user.rewardDebt;

        if (pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }

        user.rewardDebt = (user.shares * accTokenPerShare) / PRECISION_FACTOR;

        require(
            pending < claimSanityLimit,
            "CZR: Sanity check failed. Request limit raise."
        );
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (block.timestamp > timestampLast && totalShares != 0) {
            uint256 multiplier = _getMultiplier(timestampLast, block.timestamp);
            uint256 cakeReward = multiplier * rewardPerSecond;
            uint256 adjustedTokenPerShare = accTokenPerShare +
                ((cakeReward * PRECISION_FACTOR) / totalShares);
            return
                (user.shares * adjustedTokenPerShare) /
                PRECISION_FACTOR -
                user.rewardDebt;
        } else {
            return
                (user.shares * accTokenPerShare) /
                PRECISION_FACTOR -
                user.rewardDebt;
        }
    }

    function withdraw(address _account, uint256 _amount)
        external
        nonReentrant
        onlyOwner
    {
        UserInfo storage user = userInfo[_account];
        require(user.shares >= _amount, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = (user.shares * accTokenPerShare) /
            PRECISION_FACTOR -
            user.rewardDebt;

        if (_amount > 0) {
            user.shares -= _amount;
            totalShares -= _amount;
        }

        if (pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }

        user.rewardDebt = (user.shares * accTokenPerShare) / PRECISION_FACTOR;

        require(
            pending < claimSanityLimit,
            "CZR: Sanity check failed. Request limit raise."
        );
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.timestamp <= timestampLast) {
            return;
        }

        if (totalShares == 0) {
            timestampLast = block.timestamp;
            return;
        }

        uint256 multiplier = _getMultiplier(timestampLast, block.timestamp);
        uint256 rewardWad = multiplier * rewardPerSecond;
        accTokenPerShare =
            accTokenPerShare +
            ((rewardWad * PRECISION_FACTOR) / totalShares);
        timestampLast = block.timestamp;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to timestamp.
     * @param _from: timestamp to start
     * @param _to: timestamp to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= timestampEnd) {
            return _to - _from;
        } else if (_from >= timestampEnd) {
            return 0;
        } else {
            return timestampEnd - _from;
        }
    }

    function burnpoolSetStartAndDuration(
        uint256 _timestampStart,
        uint256 _durationSeconds
    ) public onlyOwner {
        timestampStart = _timestampStart;
        timestampLast = timestampStart;
        timestampEnd = timestampStart + _durationSeconds;
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        rewardPerSecond = rewardBal / rewardDuration();
    }

    function rewardDuration() public view returns (uint256) {
        return timestampEnd - timestampStart;
    }

    function setIsBoostEligibeToTrue(address[] calldata _accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            isBoostEligible[_accounts[i]] = true;
        }
    }

    function setIsBoostEligibeToFalse(address[] calldata _accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            isBoostEligible[_accounts[i]] = false;
        }
    }

    function setBoostBps(uint256 _to) external onlyOwner {
        boostBps = _to;
    }

    function setSanityLimit(uint256 _to) external onlyOwner {
        claimSanityLimit = _to;
    }
}