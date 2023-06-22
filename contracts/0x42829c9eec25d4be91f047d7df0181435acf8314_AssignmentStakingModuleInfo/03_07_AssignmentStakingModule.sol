/*
ERC20StakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IStakingModule.sol";
import "./OwnerController.sol";

/**
 * @title Assignment staking module
 *
 * @notice this staking module allows an administrator to set a fixed rate of
 * earnings for a specific user.
 */
contract AssignmentStakingModule is IStakingModule, OwnerController {
    // constant
    uint256 public constant SHARES_COEFF = 1e6;

    // members
    address private immutable _factory;

    uint256 public totalRate;
    mapping(address => uint256) public rates;

    /**
     * @param factory_ address of module factory
     */
    constructor(address factory_) {
        _factory = factory_;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function tokens()
        external
        pure
        override
        returns (address[] memory tokens_)
    {
        tokens_ = new address[](1);
        tokens_[0] = address(0x0);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function balances(
        address user
    ) external view override returns (uint256[] memory balances_) {
        balances_ = new uint256[](1);
        balances_[0] = rates[user];
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
        totals_[0] = totalRate;
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
        require(amount > 0, "asm1");
        require(sender == controller(), "asm2");
        require(data.length == 32, "asm3");

        address assignee;
        assembly {
            assignee := calldataload(132)
        }

        // increase rate
        rates[assignee] += amount;
        totalRate += amount;

        // emit
        bytes32 account = bytes32(uint256(uint160(assignee)));
        uint256 shares = amount * SHARES_COEFF;
        emit Staked(account, sender, address(0x0), amount, shares);

        return (account, shares);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function unstake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, address, uint256) {
        // validate
        require(amount > 0, "asm4");
        require(sender == controller(), "asm5");
        require(data.length == 32, "asm6");

        address assignee;
        assembly {
            assignee := calldataload(132)
        }
        uint256 r = rates[assignee];
        require(amount <= r, "asm7");

        // decrease rate
        rates[assignee] = r - amount;
        totalRate -= amount;

        // emit
        bytes32 account = bytes32(uint256(uint160(assignee)));
        uint256 shares = amount * SHARES_COEFF;
        emit Unstaked(account, sender, address(0x0), amount, shares);

        return (account, assignee, shares);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function claim(
        address sender,
        uint256 amount,
        bytes calldata
    ) external override onlyOwner returns (bytes32, address, uint256) {
        require(amount > 0, "asm8");
        require(amount <= rates[sender], "asm9");
        bytes32 account = bytes32(uint256(uint160(sender)));
        uint256 shares = amount * SHARES_COEFF;
        emit Claimed(account, sender, address(0x0), amount, shares);
        return (account, sender, shares);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function update(
        address sender,
        bytes calldata
    ) external pure override returns (bytes32) {
        return (bytes32(uint256(uint160(sender))));
    }

    /**
     * @inheritdoc IStakingModule
     */
    function clean(bytes calldata) external override {}
}