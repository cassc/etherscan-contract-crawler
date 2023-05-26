// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Vote Escrowed Token
/// @author Antfarm team
/// @notice VeAGT allows holder to vote and to get involved within the DAO
contract VoteEscrowedToken is ERC20Votes, Ownable {
    using SafeERC20 for IERC20;
    address public governanceToken;

    uint256 public locktime;

    struct Lock {
        uint256 from;
        uint256 locktime;
        uint256 reward;
        uint256 lastRewardPoints;
        address delegate;
    }

    address public rewardToken;
    uint256 private rewardTokenReserve;
    uint256 private totalRewardPoints;
    uint256 private constant POINT_MULTIPLIER = 1 ether;

    mapping(address => Lock) public locks;

    event Deposit(address sender, uint256 amount, uint256 timestamp);
    event Withdraw(address receiver, uint256 amount, uint256 timestamp);

    error NotAllowed();
    error ForbiddenTransfer();
    error NullAmount();
    error AmountTooHigh();
    error LockPeriodNotExpired();
    error NothingToClaim();

    constructor(address _governanceToken, address _rewardToken)
        ERC20("Voting Escrow Antfarm Governance Token", "veAGT")
        ERC20Permit("VotingEscrowGovernanceToken")
    {
        require(_governanceToken != address(0), "NULL_AGT_ADDRESS");
        governanceToken = _governanceToken;
        require(_rewardToken != address(0), "NULL_REWARD_ADDRESS");
        rewardToken = _rewardToken;
        locktime = 4 weeks;
    }

    modifier disburse() {
        uint256 amount = IERC20(rewardToken).balanceOf(address(this)) -
            rewardTokenReserve;

        if (amount > 0) {
            totalRewardPoints += (amount * POINT_MULTIPLIER) / totalSupply();
            rewardTokenReserve += amount;
        }

        _;
    }

    modifier updateRewards(address _address) {
        // Update rewards
        uint256 owing = newRewards(_address, totalRewardPoints);
        if (owing > 0) {
            locks[_address].reward += owing;
        }

        locks[_address].lastRewardPoints = totalRewardPoints;

        _;
    }

    modifier updateLock(address _address) {
        // Update locktime
        locks[_address].from = block.timestamp;
        locks[_address].locktime = locktime;
        _;
    }

    modifier isDelegate(address _owner) {
        if (locks[_owner].delegate != msg.sender) revert NotAllowed();
        _;
    }

    /// @notice Calculates the amount owed on top of Lock.reward
    /// @param _address Calculate amount for
    /// @param _totalRewardPoints Total reward points, useful to calulate without previous disburse
    function newRewards(address _address, uint256 _totalRewardPoints)
        internal
        view
        returns (uint256 amount)
    {
        uint256 newRewardPoints = _totalRewardPoints -
            locks[_address].lastRewardPoints;
        amount = (balanceOf(_address) * newRewardPoints) / POINT_MULTIPLIER;
    }

    /// @notice Get the amout of rewards claimable after a disburse
    /// @param _address Address to claim
    /// @return amount Claimable ATF amount
    function claimableRewards(address _address)
        external
        view
        returns (uint256 amount)
    {
        uint256 temptotalRewardPoints = totalRewardPoints;

        // Recalculate total reward points
        uint256 newAmount = IERC20(rewardToken).balanceOf(address(this)) -
            rewardTokenReserve;
        if (newAmount > 0) {
            temptotalRewardPoints +=
                (newAmount * POINT_MULTIPLIER) /
                totalSupply();
        }

        uint256 newReward = newRewards(_address, temptotalRewardPoints);
        amount = locks[_address].reward + newReward;
    }

    /// @notice Update the `_locktime` to wait before a withdrawal
    function updateLocktime(uint256 _locktime) external onlyOwner {
        locktime = _locktime;
    }

    /// @notice Deposit `_amount` tokens for `msg.sender`
    /// @param _amount AGT amount to deposit
    function deposit(uint256 _amount)
        external
        disburse
        updateRewards(msg.sender)
        updateLock(msg.sender)
    {
        if (_amount == 0) revert NullAmount();
        IERC20(governanceToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        _mint(msg.sender, _amount);
        emit Deposit(msg.sender, _amount, block.timestamp);
    }

    /// @notice Withdraw all tokens for `msg.sender`
    /// Non claimed rewards are distributed to other voters
    function withdraw() external disburse updateRewards(msg.sender) {
        Lock memory lock = locks[msg.sender];
        if (lock.from + lock.locktime > block.timestamp)
            revert LockPeriodNotExpired();

        uint256 _amount = balanceOf(msg.sender);
        if (_amount == 0) revert NullAmount();

        releaseStakingRewards(_amount);

        _burn(msg.sender, _amount);
        IERC20(governanceToken).safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount, block.timestamp);
    }

    /// @notice Withdraw a specific amount of tokens for `msg.sender`
    /// Non claimed rewards are distributed to other voters
    function withdraw(uint256 _amount)
        external
        disburse
        updateRewards(msg.sender)
    {
        Lock memory lock = locks[msg.sender];
        if (lock.from + lock.locktime > block.timestamp)
            revert LockPeriodNotExpired();

        if (_amount > balanceOf(msg.sender)) revert AmountTooHigh();
        if (_amount == 0) revert NullAmount();

        releaseStakingRewards(_amount);

        _burn(msg.sender, _amount);
        IERC20(governanceToken).safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount, block.timestamp);
    }

    // Sets a delegate that can claim staking rewards for msg.sender
    function setDelegate(address delegate) external {
        locks[msg.sender].delegate = delegate;
    }

    function claimStakingRewards(address from)
        external
        isDelegate(from)
        disburse
        updateRewards(from)
        updateLock(from)
    {
        uint256 claimAmount = locks[from].reward;

        if (claimAmount == 0) revert NullAmount();

        locks[from].reward = 0;
        rewardTokenReserve -= claimAmount;
        IERC20(rewardToken).safeTransfer(msg.sender, claimAmount);
    }

    /// @notice Claim ATF staking rewards for `msg.sender`
    function claimStakingRewards()
        external
        disburse
        updateRewards(msg.sender)
        updateLock(msg.sender)
    {
        uint256 claimAmount = locks[msg.sender].reward;

        if (claimAmount == 0) revert NullAmount();

        locks[msg.sender].reward = 0;
        rewardTokenReserve -= claimAmount;
        IERC20(rewardToken).safeTransfer(msg.sender, claimAmount);
    }

    function releaseStakingRewards(uint256 _amount) internal {
        uint256 claimAmount = (locks[msg.sender].reward * _amount) /
            balanceOf(msg.sender);

        if (claimAmount > 0) {
            locks[msg.sender].reward -= claimAmount;
            rewardTokenReserve -= claimAmount;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        if (from != address(0) && to != address(0)) {
            revert ForbiddenTransfer();
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Votes)
    {
        super._burn(account, amount);
    }
}