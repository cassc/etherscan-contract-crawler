/*
ERC20StakingModule

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IStakingModule.sol";

/**
 * @title ERC20 staking module
 *
 * @notice this staking module allows users to deposit an amount of ERC20 token
 * in exchange for shares credited to their address. When the user
 * unstakes, these shares will be burned and a reward will be distributed.
 */
contract ERC20StakingModule is IStakingModule {
    using SafeERC20 for IERC20;

    // constant
    uint256 public constant INITIAL_SHARES_PER_TOKEN = 10**6;

    // members
    IERC20 private immutable _token;
    address private immutable _factory;

    mapping(address => uint256) public shares;
    uint256 public totalShares;

    /**
     * @param token_ the token that will be rewarded
     */
    constructor(address token_, address factory_) {
        _token = IERC20(token_);
        _factory = factory_;
    }

    /**
     * @inheritdoc IStakingModule
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
     * @inheritdoc IStakingModule
     */
    function balances(address user)
        external
        view
        override
        returns (uint256[] memory balances_)
    {
        balances_ = new uint256[](1);
        balances_[0] = _balance(user);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function factory() external view override returns (address) {
        return _factory;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function totals()
        external
        view
        override
        returns (uint256[] memory totals_)
    {
        totals_ = new uint256[](1);
        totals_[0] = _token.balanceOf(address(this));
    }

    /**
     * @inheritdoc IStakingModule
     */
    function stake(
        address user,
        uint256 amount,
        bytes calldata
    ) external override onlyOwner returns (address, uint256) {
        // validate
        require(amount > 0, "Staking amount must greater than 0");

        // transfer
        uint256 total = _token.balanceOf(address(this));
        _token.safeTransferFrom(user, address(this), amount);
        uint256 actual = _token.balanceOf(address(this)) - total;

        // mint staking shares at current rate
        uint256 minted =
            (totalShares > 0)
                ? (totalShares * actual) / total
                : actual * INITIAL_SHARES_PER_TOKEN;
        require(minted > 0, "User share must greater than 0");

        // update user staking info
        shares[user] += minted;

        // add newly minted shares to global total
        totalShares += minted;

        emit Staked(user, address(_token), amount, minted);

        return (user, minted);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function unstake(
        address user,
        uint256 amount,
        bytes calldata
    ) external override onlyOwner returns (address, uint256) {
        // validate and get shares
        uint256 burned = _shares(user, amount);

        // burn shares
        totalShares -= burned;
        shares[user] -= burned;

        // unstake
        _token.safeTransfer(user, amount);

        emit Unstaked(user, address(_token), amount, burned);

        return (user, burned);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function claim(
        address user,
        uint256 amount,
        bytes calldata
    ) external override onlyOwner returns (address, uint256) {
        uint256 s = _shares(user, amount);
        emit Claimed(user, address(_token), amount, s);
        return (user, s);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function update(address) external override {}

    /**
     * @inheritdoc IStakingModule
     */
    function clean() external override {}

    /**
     * @dev internal helper to get user balance
     * @param user address of interest
     */
    function _balance(address user) private view returns (uint256) {
        if (totalShares == 0) {
            return 0;
        }
        return (_token.balanceOf(address(this)) * shares[user]) / totalShares;
    }

    /**
     * @dev internal helper to validate and convert user stake amount to shares
     * @param user address of user
     * @param amount number of tokens to consider
     * @return shares_ equivalent number of shares
     */
    function _shares(address user, uint256 amount)
        private
        view
        returns (uint256 shares_)
    {
        // validate
        require(amount > 0, "Unstaking amount must greater than 0");
        require(totalShares > 0, "Insufficient shares in this pool");

        // convert token amount to shares
        shares_ = (totalShares * amount) / _token.balanceOf(address(this));

        require(shares_ > 0, "Shares must greater than 0");
        require(shares[user] >= shares_, "User shares exceeds total shares");
    }
}