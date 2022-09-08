//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../external/IERC677Receiver.sol";
import "../external/IERC677Token.sol";
import "../lib/FsMath.sol";
import "../lib/Utils.sol";
import "../upgrade/FsBase.sol";
import "./TokenLocker.sol";
import "./interfaces/IExternalLiquidityIncentives.sol";

/// @notice Holds incentives for liquidity that was provided in an external system, such as a
///         Uniswap pool.
///
///         Exact incentives are calculated off-chain, and certain approved EOA, called "accountant"
///         is allowed to provide incentives via this contract.
contract ExternalLiquidityIncentives is FsBase, IExternalLiquidityIncentives {
    using SafeERC20 for IERC20;

    /// @inheritdoc IExternalLiquidityIncentives
    IERC677Token public override rewardsToken;

    /// @inheritdoc IExternalLiquidityIncentives
    TokenLocker public override tokenLocker;

    /// @inheritdoc IExternalLiquidityIncentives
    mapping(address => AccountantPermissions) public override accountants;

    /// @inheritdoc IExternalLiquidityIncentives
    mapping(address => uint256) public override claimableTokens;

    /// @dev Reserves storage for future upgrades. Each contract will use exactly storage slot 1000
    ///      until 2000.  When adding new fields to this contract, one must decrement this counter
    ///      proportional to the number of uint256 slots used.
    //slither-disable-next-line unused-state
    uint256[996] private _____contractGap;

    /// @notice Only for testing our contract gap mechanism, never use in prod.
    //slither-disable-next-line constable-states,unused-state
    uint256 private ___storageMarker;

    function initialize(
        address _rewardToken,
        address _tokenLocker,
        AccountantInfo[] memory _accountants
    ) external initializer {
        initializeFsOwnable();

        rewardsToken = IERC677Token(nonNull(_rewardToken, "Zero rewardsToken"));
        tokenLocker = TokenLocker(nonNull(_tokenLocker, "Zero tokenLocker"));
        for (uint256 i = 0; i < _accountants.length; ++i) {
            AccountantInfo memory info = _accountants[i];
            accountants[info.accountant] = info.permissions;

            emit AccountantAdded(info.accountant, info.permissions);
        }
    }

    /// @inheritdoc IExternalLiquidityIncentives
    function addAccountant(AccountantInfo calldata info) external override onlyOwner {
        require(
            (info.permissions == AccountantPermissions.Add ||
                info.permissions == AccountantPermissions.Adjust),
            "Invalid permission"
        );
        accountants[info.accountant] = info.permissions;

        emit AccountantAdded(info.accountant, info.permissions);
    }

    /// @inheritdoc IExternalLiquidityIncentives
    function removeAccountant(address accountant) external override onlyOwner {
        delete accountants[accountant];

        emit AccountantRemoved(accountant);
    }

    /// @notice Accepts tokens from accountants, allowing them to increase the provider liquidity
    ///         incentive balances.  This call does not allow any balances to be decreased.
    function onTokenTransfer(
        address from,
        uint256 addedIncentives,
        bytes calldata data
    ) external override returns (bool success) {
        require(msg.sender == address(rewardsToken), "Wrong token");
        require(accountants[from] != AccountantPermissions.None, "Only accountants");

        AddIncentives memory args = abi.decode(data, (AddIncentives));
        for (uint256 i = 0; i < args.additions.length; ++i) {
            ProviderAddition memory addition = args.additions[i];
            address provider = addition.provider;
            uint256 amount = addition.amount;

            require(addedIncentives >= amount, "Not enough incentives");
            addedIncentives -= amount;

            claimableTokens[provider] += amount;
        }

        require(addedIncentives == 0, "Excess incentives");

        uint256 interval = packInterval(args.intervalStart, args.intervalEnd);
        emit IncentivesAdded(from, interval, args.intervalLast, args.scriptSha, args.additions);

        return true;
    }

    /// @inheritdoc IExternalLiquidityIncentives
    function addIncentives(
        uint64 intervalStart,
        uint64 intervalEnd,
        bool intervalLast,
        bytes20 scriptSha,
        uint256[] calldata packedAccounts
    ) external override {
        require(accountants[msg.sender] != AccountantPermissions.None, "Only accountants");

        uint256 totalAmount = 0;
        ProviderAddition[] memory additions = new ProviderAddition[](packedAccounts.length);
        for (uint256 i = 0; i < packedAccounts.length; ++i) {
            // slither-disable-next-line safe-cast
            address provider = address(uint160(packedAccounts[i]));
            uint256 amount = packedAccounts[i] >> 160;
            additions[i] = ProviderAddition(provider, amount);
            totalAmount += amount;
            claimableTokens[provider] += amount;
        }

        emit IncentivesAdded(
            msg.sender,
            packInterval(intervalStart, intervalEnd),
            intervalLast,
            scriptSha,
            additions
        );

        // Move the needed tokens from owner to this contract
        IERC20(rewardsToken).safeTransferFrom(owner(), address(this), totalAmount);
    }

    /// @inheritdoc IExternalLiquidityIncentives
    function adjustIncentives(
        uint64 intervalStart,
        uint64 intervalEnd,
        bool intervalLast,
        ProviderAdjustment[] calldata adjustments
    ) external override {
        require(
            accountants[msg.sender] == AccountantPermissions.Adjust,
            "Only 'Adjust' accountants"
        );

        // Amount of incentive tokens to be sent back to the accountant.  This value must be
        // positive at the end of all the reshuffling.  A negative `adjustmentBalance` means that
        // the contract needs more tokens than the total balance of all the liquidity providers.
        // `onTokenTransfer()` should be used for adjustments that increase incentive balances.
        int256 adjustmentBalance = 0;
        for (uint256 i = 0; i < adjustments.length; ++i) {
            ProviderAdjustment memory adjustment = adjustments[i];
            address provider = adjustment.provider;
            int256 amount = adjustment.amount;

            int256 balance = FsMath.safeCastToSigned(claimableTokens[provider]);
            balance += amount;
            require(balance >= 0, "Not enough incentives");
            claimableTokens[provider] = FsMath.safeCastToUnsigned(balance);

            adjustmentBalance -= amount;
        }

        require(adjustmentBalance >= 0, "Not enough incentives");

        uint256 interval = packInterval(intervalStart, intervalEnd);
        emit IncentivesAdjusted(msg.sender, interval, intervalLast, adjustments);

        if (adjustmentBalance > 0) {
            // This contract owner is the DAO that holds the incentives.  See `addIncentives()`.
            // So when we have excess, we put them back.
            // slither-disable-next-line safe-cast
            (IERC20(rewardsToken)).safeTransfer(owner(), uint256(adjustmentBalance));
        }
    }

    function claim(uint256 lockupTime) external override {
        uint256 amount = claimableTokens[msg.sender];
        require(amount > 0, "No incentives");

        claimableTokens[msg.sender] = 0;

        // slither-disable-next-line uninitialized-local
        TokenLocker.AddLockup memory addLockup;
        addLockup.lockupTime = lockupTime;
        addLockup.receiver = msg.sender;

        // We are not emitting any events here, as TokenLocker will emit an event when it accepts
        // new tokens.  TokenLocker event contains more information and one event per operation.
        // should be enough.
        bool success =
            rewardsToken.transferAndCall(address(tokenLocker), amount, abi.encode(addLockup));
        require(success, "transferAndCall() failed");
    }

    function setRewardsToken(address newRewardsToken) external onlyOwner {
        if (newRewardsToken == address(rewardsToken)) {
            return;
        }
        address oldRewardsToken = address(rewardsToken);
        rewardsToken = IERC677Token(FsUtils.nonNull(newRewardsToken));
        emit RewardsTokenUpdated(oldRewardsToken, newRewardsToken);
    }

    /// @notice When recording intervals into events we pack then in order to save space and use
    ///         only one topic.
    ///
    ///         `start` and `end` use the upper and the lower `128` bits of the produced `uint256`,
    ///         respectively.
    function packInterval(uint64 start, uint64 end) public pure returns (uint256) {
        return (uint256(start) << 128) | uint256(end);
    }
}