/*
ERC20FixedRewardModule

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
 * @title ERC20 fixed reward module
 *
 * @notice this reward module distributes a fixed amount of a single ERC20 token.
 *
 * @dev the fixed reward module provides a guarantee that some amount of tokens
 * will be earned over a specified time period. This can be used to create
 * incentive mechanisms such as bond sales, fixed duration payroll, and more.
 */
contract ERC20FixedRewardModule is
    IRewardModule,
    ReentrancyGuard,
    OwnerController
{
    using SafeERC20 for IERC20;
    using TokenUtils for IERC20;

    // user position
    struct Position {
        uint256 debt; // reward shares
        uint256 vested; // reward shares
        uint256 earned; // reward shares
        uint128 timestamp;
        uint128 updated;
    }

    // configuration fields
    uint256 public immutable period;
    uint256 public immutable rate;
    IERC20 private immutable _token;
    address private immutable _factory;
    IConfiguration private immutable _config;

    // state fields
    mapping(bytes32 => Position) public positions;
    uint256 public rewards;
    uint256 public debt;

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
        require(period_ > 0, "xrm1");
        require(rate_ > 0, "xrm2");

        _token = IERC20(token_);
        _config = IConfiguration(config_);
        _factory = factory_;

        period = period_;
        rate = rate_;
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
        if (rewards > 0) {
            balances_[0] = _token.getAmount(rewards, rewards - debt);
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
     *
     * @dev additional stake will bookmark earnings and rollover remainder to new unvested position
     */
    function stake(
        bytes32 account,
        address,
        uint256 shares,
        bytes calldata
    ) external override onlyOwner returns (uint256, uint256) {
        uint256 reward = (shares * rate) / 1e18;
        require(reward <= rewards - debt, "xrm3");

        Position storage pos = positions[account];
        uint256 d = pos.debt;
        if (d > 0) {
            uint256 end = pos.timestamp + period;
            require(block.timestamp > end, "xrm4"); // current stake must be fully vested
            pos.earned += d;
            pos.vested += (d * period) / (end - pos.updated);
        }
        pos.debt = reward;
        pos.timestamp = uint128(block.timestamp);
        pos.updated = uint128(block.timestamp);

        debt += reward;
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
        Position storage pos = positions[account];
        require(pos.timestamp < block.timestamp);

        // unstake debt shares
        uint256 burned = (shares * rate) / 1e18;
        {
            uint256 vested = pos.vested; // burn vested shares first
            if (vested > burned) {
                pos.vested = vested - burned;
                burned = 0;
            } else if (vested > 0) {
                burned -= vested;
                pos.vested = 0;
            }
        }
        uint256 unvested;

        // get all pending rewards
        uint256 d = pos.debt;
        uint256 end = pos.timestamp + period;
        uint256 r = pos.earned;
        uint256 e;
        if (block.timestamp > end) {
            e = d;
        } else {
            uint256 last = pos.updated;
            e = (d * (block.timestamp - last)) / (end - last);
            // lost unvested reward shares
            unvested = (burned * (end - block.timestamp)) / period;
            if (d - e - unvested < 1e3) unvested = d - e; // dust
        }

        // update user position
        pos.debt = d - e - unvested;
        // (pos.vested updated above)
        pos.earned = 0;
        if (pos.debt > 0 || pos.vested > 0) {
            // update timestamp
            pos.updated = uint128(
                block.timestamp < end ? block.timestamp : end
            );
        } else {
            // delete position
            pos.updated = 0;
            pos.timestamp = 0;
        }

        // reduce global debt
        if (unvested > 0) debt -= unvested;

        // distribute rewards
        r += e;
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
        // get all pending rewards
        Position storage pos = positions[account];
        uint256 d = pos.debt;
        uint256 end = pos.timestamp + period;
        uint256 r = pos.earned;
        uint256 e;
        if (block.timestamp > end) {
            e = d;
            pos.updated = uint128(end);
        } else {
            uint256 last = pos.updated;
            e = (d * (block.timestamp - last)) / (end - last);
            pos.updated = uint128(block.timestamp);
        }

        // update user position
        pos.debt = d - e;
        pos.earned = 0;
        // (pos.updated set above)

        // distribute rewards
        r += e;
        if (r > 0) {
            _distribute(receiver, r);
        }

        return (0, 0);
    }

    /**
     * @inheritdoc IRewardModule
     */
    function update(bytes32, address, bytes calldata) external override {}

    /**
     * @inheritdoc IRewardModule
     */
    function clean(bytes calldata) external override {}

    // -- ERC20FixedRewardModule ----------------------------------------

    /**
     * @notice fund module by depositing reward tokens
     * @dev this is a public method callable by any account or contract
     * @param amount number of reward tokens to deposit
     */
    function fund(uint256 amount) external nonReentrant {
        require(amount > 0, "xrm5");

        // get fees
        (address receiver, uint256 feeRate) = _config.getAddressUint96(
            keccak256("gysr.core.fixed.fund.fee")
        );

        // do funding transfer, fee processing, and reward shares accounting
        uint256 minted = _token.receiveWithFee(
            rewards,
            msg.sender,
            amount,
            receiver,
            feeRate
        );
        rewards += minted;

        emit RewardsFunded(address(_token), amount, minted, block.timestamp);
    }

    /**
     * @notice withdraw uncommitted reward tokens from module
     * @param amount number of reward tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        requireController();

        // validate excess budget
        require(amount > 0, "xrm6");
        require(amount <= _token.balanceOf(address(this)), "xrm7");
        uint256 shares = _token.getShares(rewards, amount);
        require(shares > 0);
        require(shares <= rewards - debt, "xrm8");

        // withdraw
        rewards -= shares;
        _token.safeTransfer(msg.sender, amount);
        emit RewardsWithdrawn(address(_token), amount, shares, block.timestamp);
    }

    // -- ERC20FixedRewardModule internal -------------------------------

    /**
     * @dev internal method to distribute rewards
     * @param user address of user
     * @param shares number of shares burned
     */
    function _distribute(address user, uint256 shares) private {
        // compute reward amount in tokens
        uint256 amount = _token.getAmount(rewards, shares);

        // update overall reward shares
        rewards -= shares;
        debt -= shares;

        // do reward
        _token.safeTransfer(user, amount);
        emit RewardsDistributed(user, address(_token), amount, shares);
    }
}