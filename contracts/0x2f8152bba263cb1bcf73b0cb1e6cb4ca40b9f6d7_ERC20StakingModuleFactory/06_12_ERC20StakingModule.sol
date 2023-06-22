/*
ERC20StakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IStakingModule.sol";
import "./OwnerController.sol";
import "./TokenUtils.sol";

/**
 * @title ERC20 staking module
 *
 * @notice this staking module allows users to deposit an amount of ERC20 token
 * in exchange for shares credited to their address. When the user
 * unstakes, these shares will be burned and a reward will be distributed.
 */
contract ERC20StakingModule is IStakingModule, OwnerController {
    using SafeERC20 for IERC20;
    using TokenUtils for IERC20;

    // events
    event Approval(address indexed user, address indexed operator, bool value);

    // members
    IERC20 private immutable _token;
    address private immutable _factory;

    mapping(address => uint256) public shares;
    uint256 public totalShares;
    mapping(address => mapping(address => bool)) public approvals;

    /**
     * @param token_ the token that will be staked
     * @param factory_ address of module factory
     */
    constructor(address token_, address factory_) {
        require(token_ != address(0));
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
    function balances(
        address user
    ) external view override returns (uint256[] memory balances_) {
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
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, uint256) {
        // validate
        require(amount > 0, "sm1");
        address account = _account(sender, data);

        // transfer
        uint256 minted = _token.receiveAmount(totalShares, sender, amount);

        // update user staking info
        shares[account] += minted;

        // add newly minted shares to global total
        totalShares += minted;

        bytes32 account_ = bytes32(uint256(uint160(account)));
        emit Staked(account_, sender, address(_token), amount, minted);

        return (account_, minted);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function unstake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, address, uint256) {
        // validate and get shares
        address account = _account(sender, data);
        uint256 burned = _shares(account, amount);

        // burn shares
        totalShares -= burned;
        shares[account] -= burned;

        // unstake
        _token.safeTransfer(sender, amount);

        bytes32 account_ = bytes32(uint256(uint160(account)));
        emit Unstaked(account_, sender, address(_token), amount, burned);

        return (account_, sender, burned);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function claim(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, address, uint256) {
        address account = _account(sender, data);
        uint256 s = _shares(account, amount);
        bytes32 account_ = bytes32(uint256(uint160(account)));
        emit Claimed(account_, sender, address(_token), amount, s);
        return (account_, sender, s);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function update(
        address sender,
        bytes calldata data
    ) external view override returns (bytes32) {
        return (bytes32(uint256(uint160(_account(sender, data)))));
    }

    /**
     * @inheritdoc IStakingModule
     */
    function clean(bytes calldata) external override {}

    /**
     * @notice set approval for operators to act on user position
     * @param operator address of operator
     * @param value boolean to grant or revoke approval
     */
    function approve(address operator, bool value) external {
        approvals[msg.sender][operator] = value;
        emit Approval(msg.sender, operator, value);
    }

    /**
     * @dev internal helper to get user balance
     * @param user address of interest
     */
    function _balance(address user) private view returns (uint256) {
        return _token.getAmount(totalShares, shares[user]);
    }

    /**
     * @dev internal helper to validate and convert user stake amount to shares
     * @param user address of user
     * @param amount number of tokens to consider
     * @return shares_ equivalent number of shares
     */
    function _shares(
        address user,
        uint256 amount
    ) private view returns (uint256 shares_) {
        // validate
        require(amount > 0, "sm3");
        require(totalShares > 0, "sm4");

        // convert token amount to shares
        shares_ = _token.getShares(totalShares, amount);

        require(shares_ > 0, "sm5");
        require(shares[user] >= shares_, "sm6");
    }

    /**
     * @dev internal helper to get account and validate approval
     * @param sender address of sender
     * @param data either empty bytes or encoded account address
     */
    function _account(
        address sender,
        bytes calldata data
    ) private view returns (address) {
        require(data.length == 0 || data.length == 32, "sm7");

        if (data.length > 0) {
            address account;
            assembly {
                account := calldataload(132)
            }
            require(approvals[account][sender], "sm8");
            return account;
        } else {
            return sender;
        }
    }
}