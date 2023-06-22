/*
ERC20LinearRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IRewardModule.sol";
import "./interfaces/IConfiguration.sol";
import "./OwnerController.sol";
import "./TokenUtils.sol";

/**
 * @title ERC20 linear reward module
 *
 * @notice this reward module distributes a single ERC20 token at a continuous fixed rate.
 *
 * @dev the linear reward module provides a guarantee that a constant reward rate
 * will be earned over a specified time period. This can be used to create
 * incentive mechanisms such as streaming payroll, equity vesting, fixed rate
 * yield farms, and more.
 */
contract ERC20LinearRewardModule is
    IRewardModule,
    ReentrancyGuard,
    OwnerController
{
    using SafeERC20 for IERC20;
    using TokenUtils for IERC20;

    // user position
    struct Position {
        uint256 shares;
        uint256 timestamp;
        uint256 earned;
    }

    // configuration fields
    uint256 public immutable period;
    uint256 public immutable rate;
    IERC20 private immutable _token;
    address private immutable _factory;
    IConfiguration private immutable _config;

    // state fields
    mapping(bytes32 => Position) public positions;
    uint256 public stakingShares;
    uint256 public rewardShares;
    uint256 public elapsed; // seconds
    uint256 public earned; // shares
    uint256 public lastUpdated;

    /**
     * @param token_ the token that will be rewarded
     * @param period_ time period (seconds)
     * @param rate_ constant reward rate (shares / share second)
     * @param config_ address for configuration contract
     * @param factory_ address of module factory
     */
    constructor(
        address token_,
        uint256 period_,
        uint256 rate_,
        address config_,
        address factory_
    ) {
        require(token_ != address(0));
        require(period_ > 0, "lrm1");
        require(rate_ > 0, "lrm2");

        _token = IERC20(token_);
        _config = IConfiguration(config_);
        _factory = factory_;

        period = period_;
        rate = rate_;

        lastUpdated = block.timestamp;
    }

    // -- IRewardModule -------------------------------------------------------

    /**
     * @inheritdoc IRewardModule
     */
    function tokens()
        external
        view
        override
        returns (address[] memory tokens_)
    {
        tokens_ = new address[](1);
        tokens_[0] = address(_token);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function balances()
        external
        view
        override
        returns (uint256[] memory balances_)
    {
        balances_ = new uint256[](1);
        if (rewardShares > 0) {
            balances_[0] = _token.getAmount(
                rewardShares,
                rewardShares - earned
            );
        }
    }

    /**
     * @inheritdoc IRewardModule
     */
    function usage() external pure override returns (uint256) {
        return 0;
    }

    /**
     * @inheritdoc IRewardModule
     */
    function factory() external view override returns (address) {
        return _factory;
    }

    /**
     * @inheritdoc IRewardModule
     */
    function stake(
        bytes32 account,
        address,
        uint256 shares,
        bytes calldata
    ) external override onlyOwner returns (uint256, uint256) {
        _update();

        uint256 ss = stakingShares + shares;
        require((ss * rate * period) / 1e18 < rewardShares - earned, "lrm3");

        Position storage pos = positions[account];
        uint256 s = pos.shares;
        if (s > 0) {
            pos.earned += (s * rate * (elapsed - pos.timestamp)) / 1e18;
        }
        pos.shares = s + shares;
        pos.timestamp = elapsed;

        stakingShares = ss;
        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function unstake(
        bytes32 account,
        address,
        address receiver,
        uint256 shares,
        bytes calldata
    ) external override onlyOwner returns (uint256, uint256) {
        _update();

        Position storage pos = positions[account];
        uint256 s = pos.shares;
        assert(shares <= s); // note: we assume shares has been validated upstream

        // get all pending rewards
        uint256 r = pos.earned + (s * rate * (elapsed - pos.timestamp)) / 1e18;

        // update user position
        if (shares < s) {
            pos.shares -= shares;
            pos.timestamp = elapsed;
            pos.earned = 0;
        } else {
            delete positions[account];
        }
        stakingShares -= shares;

        // distribute rewards
        if (r > 0) {
            _distribute(receiver, r);
        }

        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function claim(
        bytes32 account,
        address,
        address receiver,
        uint256,
        bytes calldata
    ) external override onlyOwner returns (uint256, uint256) {
        _update();

        Position storage pos = positions[account];

        // get all pending rewards
        uint256 r = pos.earned +
            (pos.shares * rate * (elapsed - pos.timestamp)) /
            1e18;

        // reset user position
        pos.earned = 0;
        pos.timestamp = elapsed;

        // distribute rewards
        if (r > 0) {
            _distribute(receiver, r);
        }

        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function update(bytes32, address, bytes calldata) external override {
        requireOwner();
        _update();
    }

    /**
     * @inheritdoc IRewardModule
     */
    function clean(bytes calldata) external override {
        requireOwner();
        _update();
    }

    // -- ERC20LinearRewardModule ----------------------------------------

    /**
     * @notice fund module by depositing reward tokens
     * @dev this is a public method callable by any account or contract
     * @param amount number of reward tokens to deposit
     */
    function fund(uint256 amount) external nonReentrant {
        require(amount > 0, "lrm4");
        _update();

        // get fees
        (address receiver, uint256 feeRate) = _config.getAddressUint96(
            keccak256("gysr.core.linear.fund.fee")
        );

        // do funding transfer, fee processing, and reward shares accounting
        uint256 minted = _token.receiveWithFee(
            rewardShares,
            msg.sender,
            amount,
            receiver,
            feeRate
        );

        rewardShares += minted;

        emit RewardsFunded(address(_token), amount, minted, block.timestamp);
    }

    /**
     * @notice withdraw uncommited reward tokens from module
     * @param amount number of reward tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        requireController();
        _update();

        // validate excess budget
        require(amount > 0, "lrm5");
        require(amount <= _token.balanceOf(address(this)), "lrm6");
        uint256 shares = _token.getShares(rewardShares, amount);
        require(shares > 0);
        require(
            (stakingShares * rate * period) / 1e18 + shares <
                rewardShares - earned,
            "lrm7"
        );

        // withdraw
        rewardShares -= shares;
        _token.safeTransfer(msg.sender, amount);
        emit RewardsWithdrawn(address(_token), amount, shares, block.timestamp);
    }

    // -- ERC20LinearRewardModule internal -------------------------------

    /**
     * @dev internal method to distribute rewards
     * @param user address of user
     * @param shares number of shares burned
     */
    function _distribute(address user, uint256 shares) private {
        // compute reward amount in tokens
        uint256 amount = _token.getAmount(rewardShares, shares);

        // update overall reward shares
        rewardShares -= shares;
        earned -= shares;

        // do reward
        _token.safeTransfer(user, amount);
        emit RewardsDistributed(user, address(_token), amount, shares);
    }

    /**
     * @dev internal implementation of common update method
     */
    function _update() private {
        uint256 budget = rewardShares - earned;
        uint256 e = block.timestamp - lastUpdated;
        lastUpdated = block.timestamp;
        if (budget == 0) return; // totally out

        uint256 totalRate = (stakingShares * rate) / 1e18;
        uint256 r = totalRate * e;

        if (budget < r) {
            // over budget, clip elapsed
            e = budget / totalRate;
            r = totalRate * e;
        }

        // update accumulators
        elapsed += e;
        earned += r;
    }
}