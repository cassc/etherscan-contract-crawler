//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LockBalanceIncentives.sol";
import "../external/IERC677Receiver.sol";
import "../external/IERC677Token.sol";
import "./IStakingIncentives.sol";
import "../exchange/interfaces/IExchange.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title StakingIncentives allow users to stake a token to receive a reward.
contract StakingIncentives is LockBalanceIncentives, IStakingIncentives {
    using SafeERC20 for IERC20;

    uint256 constant STAKING_TIME = 3 days;

    /// @notice The staking token that this contract uses
    IERC677Token public stakingToken;

    struct WithdrawRequest {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => WithdrawRequest) public withdrawRequests;

    /// @dev Reserves storage for future upgrades. Each contract will use exactly storage slot 1000 until 2000.
    ///      When adding new fields to this contract, one must decrement this counter proportional to the
    ///      number of uint256 slots used.
    //slither-disable-next-line unused-state
    uint256[985] private _____contractGap;

    /// @notice Only for testing our contract gap mechanism, never use in prod.
    //slither-disable-next-line constable-states,unused-state
    uint256 private ___storageMarker;

    function initialize(
        address _stakingToken,
        address _treasury,
        address _rewardsToken
    ) external initializer {
        stakingToken = IERC677Token(nonNull(_stakingToken));
        LockBalanceIncentives.initializeLockBalanceIncentives(_treasury, _rewardsToken);
    }

    /// @notice Request a withdraw from the staking contract
    ///         The actual withdraw needs to be done with `withdraw`
    /// @param amount The amount to withdraw
    function requestWithdraw(uint256 amount) external {
        // Do withdraw deducts from the users balance
        doWithdraw(amount);

        // Create a withdraw request (or potentially add to an exisitng one)
        WithdrawRequest storage request = withdrawRequests[msg.sender];

        // Note that we are overriding the time here
        // A second request will reset the first one
        request.timestamp = getTime() + STAKING_TIME;
        request.amount += amount;

        emit WithdrawRequested(msg.sender, amount, request.timestamp);
    }

    /// @notice Withdraw the staking token from the contract
    ///         Withdraws need to first be requested via `requestWithdraw`
    ///         and can only be performed after `STAKING_TIME` wait.
    function withdraw() external {
        uint256 amount = handleWithdraw();
        IERC20(stakingToken).safeTransfer(msg.sender, amount);
    }

    /// @notice Withdraw liquidity corresponding to the amount of LP tokens immediate caller can
    ///         withdraw from this incentives contract. The withdrawn tokens will be sent directly
    ///         to the immediate caller.
    /// @param _minAssetAmount The minimum amount of asset tokens to redeem in exchange for the
    ///                        provided share of liquidity.
    ///                        happen regardless of the amount of asset in the result.
    /// @param _minStableAmount The minimum amount of stable tokens to redeem in exchange for the
    ///                         provided share of liquidity.
    function withdrawLiquidity(uint256 _minAssetAmount, uint256 _minStableAmount) external {
        uint256 amount = handleWithdraw();

        // slither-disable-next-line uninitialized-local
        IExchange.RemoveLiquidityDataWithReceiver memory rldWithReceiver;
        rldWithReceiver.minAssetAmount = _minAssetAmount;
        rldWithReceiver.minStableAmount = _minStableAmount;
        rldWithReceiver.receiver = msg.sender;
        bytes memory data = abi.encode(rldWithReceiver);

        // We need to send the LP tokens (stakingToken) to the exchange because:
        // 1. It needs to return the withdrawn liquidity to the LP (immediate caller)
        // 2. Only the LP token contract's owner can burn the LP tokens and the exchange is
        // that owner.
        address exchange = Ownable(address(stakingToken)).owner();
        require(stakingToken.transferAndCall(exchange, amount, data), "transferAndCall failed");
    }

    function handleWithdraw() internal returns (uint256) {
        WithdrawRequest storage request = withdrawRequests[msg.sender];

        require(request.timestamp != 0, "no request");
        require(request.timestamp <= getTime(), "too soon");

        uint256 amount = request.amount;

        delete withdrawRequests[msg.sender];

        emit Withdraw(msg.sender, amount);

        return amount;
    }

    function doWithdraw(uint256 amount) private {
        uint256 userBalance = balances[msg.sender];
        require(userBalance >= amount, "amount > balance");
        changeBalance(msg.sender, userBalance - amount);
    }

    /// @notice Deposit the staking token
    /// @param _amount The amount transferred into the contract
    /// @param _data Extra encoded data (StakingDeposit struct).
    function onTokenTransfer(
        address, /*from*/
        uint256 _amount,
        bytes calldata _data
    ) external override returns (bool success) {
        // This contract only accepts the staking token
        require(address(stakingToken) == msg.sender, "wrong token");

        StakingDeposit memory id = abi.decode(_data, (StakingDeposit));
        require(id.account != address(0), "missing data");

        changeBalance(id.account, balances[id.account] + _amount);

        return true;
    }

    /// @notice Returns the balance of a give account
    /// @param _account The account to return the balance for
    function getBalance(address _account) external view returns (uint256) {
        return balances[_account];
    }

    /// @notice Emitted when a user requests a withdraw
    ///         This stops the user receiving rewards for the staking token
    /// @param account The account requesting a withdraw
    /// @param amount The amount requested
    /// @param timestampAvailable The timestamp at which the user can withdraw the actual funds
    event WithdrawRequested(address account, uint256 amount, uint256 timestampAvailable);

    /// @notice Emitted when a user withdraws staking tokens from the contract
    /// @param account The account withdrawing tokens
    /// @param amount The amount being withdrawn
    event Withdraw(address account, uint256 amount);
}