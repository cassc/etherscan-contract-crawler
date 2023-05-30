// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./interfaces/IAssetPool.sol";
import "./interfaces/IAssetPoolUpgrade.sol";
import "./RewardsPool.sol";
import "./UnderwriterToken.sol";
import "./GovernanceUtils.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Asset Pool
/// @notice Asset pool is a component of a Coverage Pool. Asset Pool
///         accepts a single ERC20 token as collateral, and returns an
///         underwriter token. For example, an asset pool might accept deposits
///         in KEEP in return for covKEEP underwriter tokens. Underwriter tokens
///         represent an ownership share in the underlying collateral of the
///         Asset Pool.
contract AssetPool is Ownable, IAssetPool {
    using SafeERC20 for IERC20;
    using SafeERC20 for UnderwriterToken;

    IERC20 public immutable collateralToken;
    UnderwriterToken public immutable underwriterToken;

    RewardsPool public immutable rewardsPool;

    IAssetPoolUpgrade public newAssetPool;

    /// @notice The time it takes the underwriter to withdraw their collateral
    ///         and rewards from the pool. This is the time that needs to pass
    ///         between initiating and completing the withdrawal. During that
    ///         time, underwriter is still earning rewards and their share of
    ///         the pool is still a subject of a possible coverage claim.
    uint256 public withdrawalDelay = 21 days;
    uint256 public newWithdrawalDelay;
    uint256 public withdrawalDelayChangeInitiated;

    /// @notice The time the underwriter has after the withdrawal delay passed
    ///         to complete the withdrawal. During that time, underwriter is
    ///         still earning rewards and their share of the pool is still
    ///         a subject of a possible coverage claim.
    ///         After the withdrawal timeout elapses, tokens stay in the pool
    ///         and the underwriter has to initiate the withdrawal again and
    ///         wait for the full withdrawal delay to complete the withdrawal.
    uint256 public withdrawalTimeout = 2 days;
    uint256 public newWithdrawalTimeout;
    uint256 public withdrawalTimeoutChangeInitiated;

    mapping(address => uint256) public withdrawalInitiatedTimestamp;
    mapping(address => uint256) public pendingWithdrawal;

    event Deposited(
        address indexed underwriter,
        uint256 amount,
        uint256 covAmount
    );

    event CoverageClaimed(
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );

    event WithdrawalInitiated(
        address indexed underwriter,
        uint256 covAmount,
        uint256 timestamp
    );
    event WithdrawalCompleted(
        address indexed underwriter,
        uint256 amount,
        uint256 covAmount,
        uint256 timestamp
    );

    event ApprovedAssetPoolUpgrade(address newAssetPool);
    event CancelledAssetPoolUpgrade(address cancelledAssetPool);
    event AssetPoolUpgraded(
        address indexed underwriter,
        uint256 collateralAmount,
        uint256 covAmount,
        uint256 timestamp
    );

    event WithdrawalDelayUpdateStarted(
        uint256 withdrawalDelay,
        uint256 timestamp
    );
    event WithdrawalDelayUpdated(uint256 withdrawalDelay);
    event WithdrawalTimeoutUpdateStarted(
        uint256 withdrawalTimeout,
        uint256 timestamp
    );
    event WithdrawalTimeoutUpdated(uint256 withdrawalTimeout);

    /// @notice Reverts if the withdrawal governance delay has not passed yet or
    ///         if the change was not yet initiated.
    /// @param changeInitiatedTimestamp The timestamp at which the change has
    ///        been initiated
    modifier onlyAfterWithdrawalGovernanceDelay(
        uint256 changeInitiatedTimestamp
    ) {
        require(changeInitiatedTimestamp > 0, "Change not initiated");
        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp - changeInitiatedTimestamp >=
                withdrawalGovernanceDelay(),
            "Governance delay has not elapsed"
        );
        _;
    }

    constructor(
        IERC20 _collateralToken,
        UnderwriterToken _underwriterToken,
        address rewardsManager
    ) {
        collateralToken = _collateralToken;
        underwriterToken = _underwriterToken;

        rewardsPool = new RewardsPool(
            _collateralToken,
            address(this),
            rewardsManager
        );
    }

    /// @notice Accepts the given amount of collateral token as a deposit and
    ///         mints underwriter tokens representing pool's ownership.
    ///         Optional data in extraData may include a minimal amount of
    ///         underwriter tokens expected to be minted for a depositor. There
    ///         are cases when an amount of minted tokens matters for a
    ///         depositor, as tokens might be used in third party exchanges.
    /// @dev This function is a shortcut for approve + deposit.
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata extraData
    ) external {
        require(msg.sender == token, "Only token caller allowed");
        require(
            token == address(collateralToken),
            "Unsupported collateral token"
        );

        uint256 toMint = _calculateTokensToMint(amount);
        if (extraData.length != 0) {
            require(extraData.length == 32, "Unexpected data length");
            uint256 minAmountToMint = abi.decode(extraData, (uint256));
            require(
                minAmountToMint <= toMint,
                "Amount to mint is smaller than the required minimum"
            );
        }

        _deposit(from, amount, toMint);
    }

    /// @notice Accepts the given amount of collateral token as a deposit and
    ///         mints underwriter tokens representing pool's ownership.
    /// @dev Before calling this function, collateral token needs to have the
    ///      required amount accepted to transfer to the asset pool.
    /// @param amountToDeposit Collateral tokens amount that a user deposits to
    ///                        the asset pool
    /// @return The amount of minted underwriter tokens
    function deposit(uint256 amountToDeposit)
        external
        override
        returns (uint256)
    {
        uint256 toMint = _calculateTokensToMint(amountToDeposit);
        _deposit(msg.sender, amountToDeposit, toMint);
        return toMint;
    }

    /// @notice Accepts the given amount of collateral token as a deposit and
    ///         mints at least a minAmountToMint underwriter tokens representing
    ///         pool's ownership.
    /// @dev Before calling this function, collateral token needs to have the
    ///      required amount accepted to transfer to the asset pool.
    /// @param amountToDeposit Collateral tokens amount that a user deposits to
    ///                        the asset pool
    /// @param minAmountToMint Underwriter minimal tokens amount that a user
    ///                        expects to receive in exchange for the deposited
    ///                        collateral tokens
    /// @return The amount of minted underwriter tokens
    function depositWithMin(uint256 amountToDeposit, uint256 minAmountToMint)
        external
        override
        returns (uint256)
    {
        uint256 toMint = _calculateTokensToMint(amountToDeposit);

        require(
            minAmountToMint <= toMint,
            "Amount to mint is smaller than the required minimum"
        );

        _deposit(msg.sender, amountToDeposit, toMint);
        return toMint;
    }

    /// @notice Initiates the withdrawal of collateral and rewards from the
    ///         pool. Must be followed with completeWithdrawal call after the
    ///         withdrawal delay passes. Accepts the amount of underwriter
    ///         tokens representing the share of the pool that should be
    ///         withdrawn. Can be called multiple times increasing the pool share
    ///         to withdraw and resetting the withdrawal initiated timestamp for
    ///         each call. Can be called with 0 covAmount to reset the
    ///         withdrawal initiated timestamp if the underwriter has a pending
    ///         withdrawal. In practice 0 covAmount should be used only to
    ///         initiate the withdrawal again in case one did not complete the
    ///         withdrawal before the withdrawal timeout elapsed.
    /// @dev Before calling this function, underwriter token needs to have the
    ///      required amount accepted to transfer to the asset pool.
    function initiateWithdrawal(uint256 covAmount) external override {
        uint256 pending = pendingWithdrawal[msg.sender];
        require(
            covAmount > 0 || pending > 0,
            "Underwriter token amount must be greater than 0"
        );

        pending += covAmount;
        pendingWithdrawal[msg.sender] = pending;
        /* solhint-disable not-rely-on-time */
        withdrawalInitiatedTimestamp[msg.sender] = block.timestamp;

        emit WithdrawalInitiated(msg.sender, pending, block.timestamp);
        /* solhint-enable not-rely-on-time */

        if (covAmount > 0) {
            underwriterToken.safeTransferFrom(
                msg.sender,
                address(this),
                covAmount
            );
        }
    }

    /// @notice Completes the previously initiated withdrawal for the
    ///         underwriter. Anyone can complete the withdrawal for the
    ///         underwriter. The withdrawal has to be completed before the
    ///         withdrawal timeout elapses. Otherwise, the withdrawal has to
    ///         be initiated again and the underwriter has to wait for the
    ///         entire withdrawal delay again before being able to complete
    ///         the withdrawal.
    /// @return The amount of collateral withdrawn
    function completeWithdrawal(address underwriter)
        external
        override
        returns (uint256)
    {
        /* solhint-disable not-rely-on-time */
        uint256 initiatedAt = withdrawalInitiatedTimestamp[underwriter];
        require(initiatedAt > 0, "No withdrawal initiated for the underwriter");

        uint256 withdrawalDelayEndTimestamp = initiatedAt + withdrawalDelay;
        require(
            withdrawalDelayEndTimestamp < block.timestamp,
            "Withdrawal delay has not elapsed"
        );

        require(
            withdrawalDelayEndTimestamp + withdrawalTimeout >= block.timestamp,
            "Withdrawal timeout elapsed"
        );

        uint256 covAmount = pendingWithdrawal[underwriter];
        uint256 covSupply = underwriterToken.totalSupply();
        delete withdrawalInitiatedTimestamp[underwriter];
        delete pendingWithdrawal[underwriter];

        // slither-disable-next-line reentrancy-events
        rewardsPool.withdraw();

        uint256 collateralBalance = collateralToken.balanceOf(address(this));

        uint256 amountToWithdraw = (covAmount * collateralBalance) / covSupply;

        emit WithdrawalCompleted(
            underwriter,
            amountToWithdraw,
            covAmount,
            block.timestamp
        );
        collateralToken.safeTransfer(underwriter, amountToWithdraw);

        /* solhint-enable not-rely-on-time */
        underwriterToken.burn(covAmount);

        return amountToWithdraw;
    }

    /// @notice Transfers collateral tokens to a new Asset Pool which previously
    ///         was approved by the governance. Upgrade does not have to obey
    ///         withdrawal delay.
    ///         Old underwriter tokens are burned in favor of new tokens minted
    ///         in a new Asset Pool. New tokens are sent directly to the
    ///         underwriter from a new Asset Pool.
    /// @param covAmount Amount of underwriter tokens used to calculate collateral
    ///                  tokens which are transferred to a new asset pool
    /// @param _newAssetPool New Asset Pool address to check validity with the one
    ///                      that was approved by the governance
    function upgradeToNewAssetPool(uint256 covAmount, address _newAssetPool)
        external
    {
        /* solhint-disable not-rely-on-time */
        require(
            address(newAssetPool) != address(0),
            "New asset pool must be assigned"
        );

        require(
            address(newAssetPool) == _newAssetPool,
            "Addresses of a new asset pool must match"
        );

        require(
            covAmount > 0,
            "Underwriter token amount must be greater than 0"
        );

        uint256 covSupply = underwriterToken.totalSupply();

        // slither-disable-next-line reentrancy-events
        rewardsPool.withdraw();

        uint256 collateralBalance = collateralToken.balanceOf(address(this));

        uint256 collateralToTransfer = (covAmount * collateralBalance) /
            covSupply;

        collateralToken.safeApprove(
            address(newAssetPool),
            collateralToTransfer
        );
        // old underwriter tokens are burned in favor of new minted in a new
        // asset pool
        underwriterToken.burnFrom(msg.sender, covAmount);
        // collateralToTransfer will be sent to a new AssetPool and new
        // underwriter tokens will be minted and transferred back to the underwriter
        newAssetPool.depositFor(msg.sender, collateralToTransfer);

        emit AssetPoolUpgraded(
            msg.sender,
            collateralToTransfer,
            covAmount,
            block.timestamp
        );
    }

    /// @notice Allows governance to set a new asset pool so the underwriters
    ///         can move their collateral tokens to a new asset pool without
    ///         having to wait for the withdrawal delay.
    function approveNewAssetPoolUpgrade(IAssetPoolUpgrade _newAssetPool)
        external
        onlyOwner
    {
        require(
            address(_newAssetPool) != address(0),
            "New asset pool can't be zero address"
        );

        newAssetPool = _newAssetPool;

        emit ApprovedAssetPoolUpgrade(address(_newAssetPool));
    }

    /// @notice Allows governance to cancel already approved new asset pool
    ///         in case of some misconfiguration.
    function cancelNewAssetPoolUpgrade() external onlyOwner {
        emit CancelledAssetPoolUpgrade(address(newAssetPool));

        newAssetPool = IAssetPoolUpgrade(address(0));
    }

    /// @notice Allows the coverage pool to demand coverage from the asset hold
    ///         by this pool and send it to the provided recipient address.
    function claim(address recipient, uint256 amount) external onlyOwner {
        emit CoverageClaimed(recipient, amount, block.timestamp);
        rewardsPool.withdraw();
        collateralToken.safeTransfer(recipient, amount);
    }

    /// @notice Lets the contract owner to begin an update of withdrawal delay
    ///         parameter value. Withdrawal delay is the time it takes the
    ///         underwriter to withdraw their collateral and rewards from the
    ///         pool. This is the time that needs to pass between initiating and
    ///         completing the withdrawal. The change needs to be finalized with
    ///         a call to finalizeWithdrawalDelayUpdate after the required
    ///         governance delay passes. It is up to the contract owner to
    ///         decide what the withdrawal delay value should be but it should
    ///         be long enough so that the possibility of having free-riding
    ///         underwriters escaping from a potential coverage claim by
    ///         withdrawing their positions from the pool is negligible.
    /// @param _newWithdrawalDelay The new value of withdrawal delay
    function beginWithdrawalDelayUpdate(uint256 _newWithdrawalDelay)
        external
        onlyOwner
    {
        newWithdrawalDelay = _newWithdrawalDelay;
        withdrawalDelayChangeInitiated = block.timestamp;
        emit WithdrawalDelayUpdateStarted(_newWithdrawalDelay, block.timestamp);
    }

    /// @notice Lets the contract owner to finalize an update of withdrawal
    ///         delay parameter value. This call has to be preceded with
    ///         a call to beginWithdrawalDelayUpdate and the governance delay
    ///         has to pass.
    function finalizeWithdrawalDelayUpdate()
        external
        onlyOwner
        onlyAfterWithdrawalGovernanceDelay(withdrawalDelayChangeInitiated)
    {
        withdrawalDelay = newWithdrawalDelay;
        emit WithdrawalDelayUpdated(withdrawalDelay);
        newWithdrawalDelay = 0;
        withdrawalDelayChangeInitiated = 0;
    }

    /// @notice Lets the contract owner to begin an update of withdrawal timeout
    ///         parameter value. The withdrawal timeout is the time the
    ///         underwriter has - after the withdrawal delay passed - to
    ///         complete the withdrawal. The change needs to be finalized with
    ///         a call to finalizeWithdrawalTimeoutUpdate after the required
    ///         governance delay passes. It is up to the contract owner to
    ///         decide what the withdrawal timeout value should be but it should
    ///         be short enough so that the time of free-riding by being able to
    ///         immediately escape from the claim is minimal and long enough so
    ///         that honest underwriters have a possibility to finalize the
    ///         withdrawal. It is all about the right proportions with
    ///         a relation to withdrawal delay value.
    /// @param  _newWithdrawalTimeout The new value of the withdrawal timeout
    function beginWithdrawalTimeoutUpdate(uint256 _newWithdrawalTimeout)
        external
        onlyOwner
    {
        newWithdrawalTimeout = _newWithdrawalTimeout;
        withdrawalTimeoutChangeInitiated = block.timestamp;
        emit WithdrawalTimeoutUpdateStarted(
            _newWithdrawalTimeout,
            block.timestamp
        );
    }

    /// @notice Lets the contract owner to finalize an update of withdrawal
    ///         timeout parameter value. This call has to be preceded with
    ///         a call to beginWithdrawalTimeoutUpdate and the governance delay
    ///         has to pass.
    function finalizeWithdrawalTimeoutUpdate()
        external
        onlyOwner
        onlyAfterWithdrawalGovernanceDelay(withdrawalTimeoutChangeInitiated)
    {
        withdrawalTimeout = newWithdrawalTimeout;
        emit WithdrawalTimeoutUpdated(withdrawalTimeout);
        newWithdrawalTimeout = 0;
        withdrawalTimeoutChangeInitiated = 0;
    }

    /// @notice Grants pool shares by minting a given amount of the underwriter
    ///         tokens for the recipient address. In result, the recipient
    ///         obtains part of the pool ownership without depositing any
    ///         collateral tokens. Shares are usually granted for notifiers
    ///         reporting about various contract state changes.
    /// @dev Can be called only by the contract owner.
    /// @param recipient Address of the underwriter tokens recipient
    /// @param covAmount Amount of the underwriter tokens which should be minted
    function grantShares(address recipient, uint256 covAmount)
        external
        onlyOwner
    {
        rewardsPool.withdraw();
        underwriterToken.mint(recipient, covAmount);
    }

    /// @notice Returns the remaining time that has to pass before the contract
    ///         owner will be able to finalize withdrawal delay update.
    ///         Bear in mind the contract owner may decide to wait longer and
    ///         this value is just an absolute minimum.
    /// @return The time left until withdrawal delay update can be finalized
    function getRemainingWithdrawalDelayUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                withdrawalDelayChangeInitiated,
                withdrawalGovernanceDelay()
            );
    }

    /// @notice Returns the remaining time that has to pass before the contract
    ///         owner will be able to finalize withdrawal timeout update.
    ///         Bear in mind the contract owner may decide to wait longer and
    ///         this value is just an absolute minimum.
    /// @return The time left until withdrawal timeout update can be finalized
    function getRemainingWithdrawalTimeoutUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                withdrawalTimeoutChangeInitiated,
                withdrawalGovernanceDelay()
            );
    }

    /// @notice Returns the current collateral token balance of the asset pool
    ///         plus the reward amount (in collateral token) earned by the asset
    ///         pool and not yet withdrawn to the asset pool.
    /// @return The total value of asset pool in collateral token.
    function totalValue() external view returns (uint256) {
        return collateralToken.balanceOf(address(this)) + rewardsPool.earned();
    }

    /// @notice The time it takes to initiate and complete the withdrawal from
    ///         the pool plus 2 days to make a decision. This governance delay
    ///         should be used for all changes directly affecting underwriter
    ///         positions. This time is a minimum and the governance may choose
    ///         to wait longer before finalizing the update.
    /// @return The withdrawal governance delay in seconds
    function withdrawalGovernanceDelay() public view returns (uint256) {
        return withdrawalDelay + withdrawalTimeout + 2 days;
    }

    /// @dev Calculates underwriter tokens to mint.
    function _calculateTokensToMint(uint256 amountToDeposit)
        internal
        returns (uint256)
    {
        rewardsPool.withdraw();

        uint256 covSupply = underwriterToken.totalSupply();
        uint256 collateralBalance = collateralToken.balanceOf(address(this));

        if (covSupply == 0) {
            return amountToDeposit;
        }

        return (amountToDeposit * covSupply) / collateralBalance;
    }

    function _deposit(
        address depositor,
        uint256 amountToDeposit,
        uint256 amountToMint
    ) internal {
        require(depositor != address(this), "Self-deposit not allowed");

        require(
            amountToMint > 0,
            "Minted tokens amount must be greater than 0"
        );

        emit Deposited(depositor, amountToDeposit, amountToMint);

        underwriterToken.mint(depositor, amountToMint);
        collateralToken.safeTransferFrom(
            depositor,
            address(this),
            amountToDeposit
        );
    }
}