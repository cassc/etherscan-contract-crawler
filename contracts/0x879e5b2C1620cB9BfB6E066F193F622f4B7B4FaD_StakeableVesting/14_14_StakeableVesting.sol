// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStakeableVesting.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "api3-dao/packages/pool/contracts/interfaces/v0.8/IApi3Pool.sol";

/// @title Contract that implements a stakeable vesting of API3 tokens
/// allocated to a beneficiary, which is revocable by the owner of this
/// contract
/// @notice This contract is an implementation that is required to be cloned by
/// a StakeableVestingFactory contract. The beneficiary of the vesting is
/// expected to interact with this contract through a generic, ABI-based UI
/// such as Etherscan's. See the repo's README for instructions.
/// @dev The contract implements the Api3Pool interface explicitly instead of
/// acting as a general call forwarder (with only Api3Token interactions being
/// restricted) because the user will not be provided with a trusted frontend
/// that will encode the calls. This implementation allows general purpose
/// contract interaction frontends to be used.
contract StakeableVesting is Ownable, IStakeableVesting {
    struct Vesting {
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint192 amount;
    }

    /// @notice Api3Token address
    address public immutable override api3Token;

    /// @notice Api3Pool address
    address public immutable api3Pool;

    /// @notice Beneficiary of the vesting
    address public override beneficiary;

    /// @notice Vesting parameters, including the schedule and the amount
    Vesting public override vesting;

    /// @dev Prevents tokens from being locked by setting an unreasonably late
    /// vesting end timestamp. The vesting periods are expected to be 4 years,
    /// and we have 1 year of buffer here in case the vesting is required to
    /// start in the future.
    uint256
        private constant MAXIMUM_TIME_BETWEEN_INITIALIZATION_AND_VESTING_END =
        5 * 365 days;

    /// @dev Reverts if the sender is not the beneficiary
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Sender not beneficiary");
        _;
    }

    /// @dev This contract is means to be an implementation for
    /// StakeableVestingFactory to clone. To prevent the implementaion from
    /// being used, the contract is rendered uninitializable and the ownership
    /// is renounced.
    /// @param _api3Token Api3Token address
    /// @param _api3Pool Api3Pool address
    constructor(address _api3Token, address _api3Pool) {
        require(_api3Token != address(0), "Api3Token address zero");
        api3Token = _api3Token;
        require(_api3Pool != address(0), "Api3Pool address zero");
        api3Pool = _api3Pool;
        beneficiary = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
        renounceOwnership();
    }

    /// @notice Initializes a newly cloned StakeableVesting
    /// @dev Since beneficiary is required to be zero address, only clones of
    /// this contract can be initialized.
    /// Anyone can initialize a StakeableVesting clone. The user is required to
    /// prevent others from initializing their clones, for example, by
    /// initializing the clone in the same transaction as it is deployed in.
    /// The StakeableVesting needs to have exactly `_amount` API3 tokens.
    /// @param _owner Owner of this StakeableVesting clone, i.e., the account
    /// that can revoke the vesting
    /// @param _beneficiary Beneficiary of the vesting
    /// @param _startTimestamp Starting timestamp of the vesting
    /// @param _endTimestamp Ending timestamp of the vesting
    /// @param _amount Amount of tokens to be vested over the period
    function initialize(
        address _owner,
        address _beneficiary,
        uint32 _startTimestamp,
        uint32 _endTimestamp,
        uint192 _amount
    ) external override {
        require(beneficiary == address(0), "Already initialized");
        require(_owner != address(0), "Owner address zero");
        require(_beneficiary != address(0), "Beneficiary address zero");
        require(_startTimestamp != 0, "Start timestamp zero");
        require(_endTimestamp > _startTimestamp, "End not later than start");
        require(
            _endTimestamp <=
                block.timestamp +
                    MAXIMUM_TIME_BETWEEN_INITIALIZATION_AND_VESTING_END,
            "End is too far in the future"
        );
        require(_amount != 0, "Amount zero");
        require(
            IERC20(api3Token).balanceOf(address(this)) == _amount,
            "Balance is not vesting amount"
        );
        _transferOwnership(_owner);
        beneficiary = _beneficiary;
        vesting = Vesting({
            startTimestamp: _startTimestamp,
            endTimestamp: _endTimestamp,
            amount: _amount
        });
    }

    /// @notice Called by the owner to set the beneficiary
    /// @dev This can be used to revoke the vesting by setting the beneficiary
    /// to be the owner, or to update the beneficiary address, e.g., because
    /// the previous beneficiary account was compromised
    /// @param _beneficiary Beneficiary of the vesting
    function setBeneficiary(address _beneficiary) external override onlyOwner {
        require(_beneficiary != address(0), "Beneficiary address zero");
        beneficiary = _beneficiary;
        emit SetBeneficiary(_beneficiary);
    }

    /// @notice Called by the owner to withdraw all API3 tokens
    /// @dev This function does not modify the state on purpose, so that the
    /// vesting can easily be reinstituted by returning the withdrawn amount
    function withdrawAsOwner() external override onlyOwner {
        uint256 withdrawalAmount = IERC20(api3Token).balanceOf(address(this));
        require(withdrawalAmount != 0, "No balance to withdraw");
        IERC20(api3Token).transfer(msg.sender, withdrawalAmount);
        emit WithdrawnAsOwner(withdrawalAmount);
    }

    /// @notice Called by the beneficiary as many tokens the vesting schedule
    /// allows
    function withdrawAsBeneficiary() external override onlyBeneficiary {
        uint256 balance = IERC20(api3Token).balanceOf(address(this));
        require(balance != 0, "Balance zero");
        uint256 totalBalance = balance + poolBalance();
        uint256 unvestedAmountInTotalBalance = unvestedAmount();
        require(
            totalBalance > unvestedAmountInTotalBalance,
            "Tokens in balance not vested yet"
        );
        uint256 vestedAmountInTotalBalance = totalBalance -
            unvestedAmountInTotalBalance;
        uint256 withdrawalAmount = vestedAmountInTotalBalance > balance
            ? balance
            : vestedAmountInTotalBalance;
        IERC20(api3Token).transfer(msg.sender, withdrawalAmount);
        emit WithdrawnAsBeneficiary(withdrawalAmount);
    }

    /// @notice Called by the beneficiary to have the StakeableVesting deposit
    /// tokens at the pool
    /// @param amount Amount of tokens
    function depositAtPool(uint256 amount) external override onlyBeneficiary {
        IERC20(api3Token).approve(api3Pool, amount);
        IApi3Pool(api3Pool).depositRegular(amount);
    }

    /// @notice Called by the beneficiary to have the StakeableVesting withdraw
    /// tokens from the pool
    /// @param amount Amount of tokens
    function withdrawAtPool(uint256 amount) external override onlyBeneficiary {
        IApi3Pool(api3Pool).withdrawRegular(amount);
    }

    /// @notice Called by the beneficiary to have the StakeableVesting withdraw
    /// tokens from the pool based on the precalculated amount of locked
    /// staking rewards
    /// @dev This is only needed if the gas cost of calculating the amount of
    /// locked staking rewards exceeds the block gas limit. See the Api3Pool
    /// code for more details.
    /// `precalculateUserLocked()` at Api3Pool needs to be called before using
    /// this function. Since anyone can call it for any user address, it is not
    /// included in this contract.
    /// @param amount Amount of tokens
    function withdrawPrecalculatedAtPool(
        uint256 amount
    ) external override onlyBeneficiary {
        IApi3Pool(api3Pool).withdrawPrecalculated(amount);
    }

    /// @notice Called by the beneficiary to have the StakeableVesting stake
    /// tokens at the pool
    /// @param amount Amount of tokens
    function stakeAtPool(uint256 amount) external override onlyBeneficiary {
        IApi3Pool(api3Pool).stake(amount);
    }

    /// @notice Called by the beneficiary to have the StakeableVesting schedule
    /// an unstaking of tokens at the pool
    /// @param amount Amount of tokens
    function scheduleUnstakeAtPool(
        uint256 amount
    ) external override onlyBeneficiary {
        IApi3Pool(api3Pool).scheduleUnstake(amount);
    }

    /// @notice Called by the beneficiary to have the unstaking that the
    /// StakeableVesting has scheduled to be executed
    /// @dev Anyone can call this function at Api3Pool with the
    /// StakeableVesting address. This function is implemented for the
    /// convenience of the user.
    function unstakeAtPool() external override {
        IApi3Pool(api3Pool).unstake(address(this));
    }

    /// @notice Called by the beneficiary to have the StakeableVesting delegate
    /// its voting power at the pool
    /// @param delegate Address of the account that the voting power will be
    /// delegated to
    function delegateAtPool(
        address delegate
    ) external override onlyBeneficiary {
        IApi3Pool(api3Pool).delegateVotingPower(delegate);
    }

    /// @notice Called by the beneficiary to have the StakeableVesting
    /// undelegate its voting power at the pool
    function undelegateAtPool() external override onlyBeneficiary {
        IApi3Pool(api3Pool).undelegateVotingPower();
    }

    function stateAtPool()
        external
        view
        override
        returns (
            uint256 unstaked,
            uint256 staked,
            uint256 unstaking,
            uint256 unstakeScheduledFor,
            uint256 lockedStakingRewards,
            address delegate,
            uint256 lastDelegationUpdateTimestamp
        )
    {
        delegate = IApi3Pool(api3Pool).userDelegate(address(this));
        lockedStakingRewards = IApi3Pool(api3Pool).userLocked(address(this));
        staked = IApi3Pool(api3Pool).userStake(address(this));
        (
            unstaked,
            ,
            unstaking,
            ,
            unstakeScheduledFor,
            lastDelegationUpdateTimestamp,

        ) = IApi3Pool(api3Pool).getUser(address(this));
    }

    /// @notice Returns the amount of tokens that are yet to be vested based on
    /// the schedule
    /// @return Amount of unvested tokens
    function unvestedAmount() public view override returns (uint256) {
        (uint32 startTimestamp, uint32 endTimestamp, uint192 amount) = (
            vesting.startTimestamp,
            vesting.endTimestamp,
            vesting.amount
        );
        if (block.timestamp <= startTimestamp) {
            return amount;
        } else if (block.timestamp >= endTimestamp) {
            return 0;
        } else {
            uint256 passedTime = block.timestamp - startTimestamp;
            uint256 totalTime = endTimestamp - startTimestamp;
            return amount - (amount * passedTime) / totalTime;
        }
    }

    /// @notice Returns the total balance of StakeableVesting at the pool
    /// @dev Even though it is not certain that the beneficiary will be able to
    /// unstake the funds that are currently staked or being unstaked without
    /// getting slashed, the contract still counts them towards their total
    /// balance in favor of the beneficiary
    /// @return Pool balance
    function poolBalance() private view returns (uint256) {
        uint256 staked = IApi3Pool(api3Pool).userStake(address(this));
        (uint256 unstaked, , uint256 unstaking, , , , ) = IApi3Pool(api3Pool)
            .getUser(address(this));
        return staked + unstaked + unstaking;
    }
}