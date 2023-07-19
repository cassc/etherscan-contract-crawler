// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {
    Streams, StreamConfig, StreamsHistory, StreamConfigImpl, StreamReceiver
} from "./Streams.sol";
import {Managed} from "./Managed.sol";
import {Splits, SplitsReceiver} from "./Splits.sol";
import {IERC20, SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

/// @notice The account metadata.
/// The key and the value are not standardized by the protocol, it's up to the users
/// to establish and follow conventions to ensure compatibility with the consumers.
struct AccountMetadata {
    /// @param key The metadata key
    bytes32 key;
    /// @param value The metadata value
    bytes value;
}

/// @notice Drips protocol contract. Automatically streams and splits funds between accounts.
///
/// The account can transfer some funds to their streams balance in the contract
/// and configure a list of receivers, to whom they want to stream these funds.
/// As soon as the streams balance is enough to cover at least 1 second of streaming
/// to the configured receivers, the funds start streaming automatically.
/// Every second funds are deducted from the streams balance and moved to their receivers.
/// The process stops automatically when the streams balance is not enough to cover another second.
///
/// Every account has a receiver balance, in which they have funds received from other accounts.
/// The streamed funds are added to the receiver balances in global cycles.
/// Every `cycleSecs` seconds the protocol adds streamed funds to the receivers' balances,
/// so recently streamed funds may not be receivable immediately.
/// `cycleSecs` is a constant configured when the Drips contract is deployed.
/// The receiver balance is independent from the streams balance,
/// to stream received funds they need to be first collected and then added to the streams balance.
///
/// The account can share collected funds with other accounts by using splits.
/// When collecting, the account gives each of their splits receivers
/// a fraction of the received funds.
/// Funds received from splits are available for collection immediately regardless of the cycle.
/// They aren't exempt from being split, so they too can be split when collected.
/// Accounts can build chains and networks of splits between each other.
/// Anybody can request collection of funds for any account,
/// which can be used to enforce the flow of funds in the network of splits.
///
/// The concept of something happening periodically, e.g. every second or every `cycleSecs` are
/// only high-level abstractions for the account, Ethereum isn't really capable of scheduling work.
/// The actual implementation emulates that behavior by calculating the results of the scheduled
/// events based on how many seconds have passed and only when the account needs their outcomes.
///
/// The contract can store at most `type(int128).max` which is `2 ^ 127 - 1` units of each token.
contract Drips is Managed, Streams, Splits {
    /// @notice Maximum number of streams receivers of a single account.
    /// Limits cost of changes in streams configuration.
    uint256 public constant MAX_STREAMS_RECEIVERS = _MAX_STREAMS_RECEIVERS;
    /// @notice The additional decimals for all amtPerSec values.
    uint8 public constant AMT_PER_SEC_EXTRA_DECIMALS = _AMT_PER_SEC_EXTRA_DECIMALS;
    /// @notice The multiplier for all amtPerSec values.
    uint160 public constant AMT_PER_SEC_MULTIPLIER = _AMT_PER_SEC_MULTIPLIER;
    /// @notice Maximum number of splits receivers of a single account.
    /// Limits the cost of splitting.
    uint256 public constant MAX_SPLITS_RECEIVERS = _MAX_SPLITS_RECEIVERS;
    /// @notice The total splits weight of an account
    uint32 public constant TOTAL_SPLITS_WEIGHT = _TOTAL_SPLITS_WEIGHT;
    /// @notice The offset of the controlling driver ID in the account ID.
    /// In other words the controlling driver ID is the highest 32 bits of the account ID.
    /// Every account ID is a 256-bit integer constructed by concatenating:
    /// `driverId (32 bits) | driverCustomData (224 bits)`.
    uint8 public constant DRIVER_ID_OFFSET = 224;
    /// @notice The total amount the protocol can store of each token.
    /// It's the minimum of _MAX_STREAMS_BALANCE and _MAX_SPLITS_BALANCE.
    uint128 public constant MAX_TOTAL_BALANCE = _MAX_STREAMS_BALANCE;
    /// @notice On every timestamp `T`, which is a multiple of `cycleSecs`, the receivers
    /// gain access to steams received during `T - cycleSecs` to `T - 1`.
    /// Always higher than 1.
    uint32 public immutable cycleSecs;
    /// @notice The minimum amtPerSec of a stream. It's 1 token per cycle.
    uint160 public immutable minAmtPerSec;
    /// @notice The ERC-1967 storage slot holding a single `DripsStorage` structure.
    bytes32 private immutable _dripsStorageSlot = _erc1967Slot("eip1967.drips.storage");

    /// @notice Emitted when a driver is registered
    /// @param driverId The driver ID
    /// @param driverAddr The driver address
    event DriverRegistered(uint32 indexed driverId, address indexed driverAddr);

    /// @notice Emitted when a driver address is updated
    /// @param driverId The driver ID
    /// @param oldDriverAddr The old driver address
    /// @param newDriverAddr The new driver address
    event DriverAddressUpdated(
        uint32 indexed driverId, address indexed oldDriverAddr, address indexed newDriverAddr
    );

    /// @notice Emitted when funds are withdrawn.
    /// @param erc20 The used ERC-20 token.
    /// @param receiver The address that the funds are sent to.
    /// @param amt The withdrawn amount.
    event Withdrawn(IERC20 indexed erc20, address indexed receiver, uint256 amt);

    /// @notice Emitted by the account to broadcast metadata.
    /// The key and the value are not standardized by the protocol, it's up to the users
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @param accountId The ID of the account emitting metadata
    /// @param key The metadata key
    /// @param value The metadata value
    event AccountMetadataEmitted(uint256 indexed accountId, bytes32 indexed key, bytes value);

    struct DripsStorage {
        /// @notice The next driver ID that will be used when registering.
        uint32 nextDriverId;
        /// @notice Driver addresses.
        mapping(uint32 driverId => address) driverAddresses;
        /// @notice The balance of each token currently stored in the protocol.
        mapping(IERC20 erc20 => Balance) balances;
    }

    /// @notice The balance currently stored in the protocol.
    struct Balance {
        /// @notice The balance currently stored in streaming.
        uint128 streams;
        /// @notice The balance currently stored in splitting.
        uint128 splits;
    }

    /// @param cycleSecs_ The length of cycleSecs to be used in the contract instance.
    /// Low value makes funds more available by shortening the average time
    /// of funds being frozen between being taken from the accounts'
    /// streams balance and being receivable by their receivers.
    /// High value makes receiving cheaper by making it process less cycles for a given time range.
    /// Must be higher than 1.
    constructor(uint32 cycleSecs_)
        Streams(cycleSecs_, _erc1967Slot("eip1967.streams.storage"))
        Splits(_erc1967Slot("eip1967.splits.storage"))
    {
        cycleSecs = Streams._cycleSecs;
        minAmtPerSec = Streams._minAmtPerSec;
    }

    /// @notice A modifier making functions callable only by the driver controlling the account.
    /// @param accountId The account ID.
    modifier onlyDriver(uint256 accountId) {
        // `accountId` has value:
        // `driverId (32 bits) | driverCustomData (224 bits)`
        // By bit shifting we get value:
        // `zeros (224 bits) | driverId (32 bits)`
        // By casting down we get value:
        // `driverId (32 bits)`
        uint32 driverId = uint32(accountId >> DRIVER_ID_OFFSET);
        _assertCallerIsDriver(driverId);
        _;
    }

    /// @notice Verifies that the caller controls the given driver ID and reverts otherwise.
    /// @param driverId The driver ID.
    function _assertCallerIsDriver(uint32 driverId) internal view {
        require(driverAddress(driverId) == msg.sender, "Callable only by the driver");
    }

    /// @notice Registers a driver.
    /// The driver is assigned a unique ID and a range of account IDs it can control.
    /// That range consists of all 2^224 account IDs with highest 32 bits equal to the driver ID.
    /// Every account ID is a 256-bit integer constructed by concatenating:
    /// `driverId (32 bits) | driverCustomData (224 bits)`.
    /// Every driver ID is assigned only to a single address,
    /// but a single address can have multiple driver IDs assigned to it.
    /// @param driverAddr The address of the driver. Must not be zero address.
    /// It should be a smart contract capable of dealing with the Drips API.
    /// It shouldn't be an EOA because the API requires making multiple calls per transaction.
    /// @return driverId The registered driver ID.
    function registerDriver(address driverAddr) public whenNotPaused returns (uint32 driverId) {
        require(driverAddr != address(0), "Driver registered for 0 address");
        DripsStorage storage dripsStorage = _dripsStorage();
        driverId = dripsStorage.nextDriverId++;
        dripsStorage.driverAddresses[driverId] = driverAddr;
        emit DriverRegistered(driverId, driverAddr);
    }

    /// @notice Returns the driver address.
    /// @param driverId The driver ID to look up.
    /// @return driverAddr The address of the driver.
    /// If the driver hasn't been registered yet, returns address 0.
    function driverAddress(uint32 driverId) public view returns (address driverAddr) {
        return _dripsStorage().driverAddresses[driverId];
    }

    /// @notice Updates the driver address. Must be called from the current driver address.
    /// @param driverId The driver ID.
    /// @param newDriverAddr The new address of the driver.
    /// It should be a smart contract capable of dealing with the Drips API.
    /// It shouldn't be an EOA because the API requires making multiple calls per transaction.
    function updateDriverAddress(uint32 driverId, address newDriverAddr) public whenNotPaused {
        _assertCallerIsDriver(driverId);
        _dripsStorage().driverAddresses[driverId] = newDriverAddr;
        emit DriverAddressUpdated(driverId, msg.sender, newDriverAddr);
    }

    /// @notice Returns the driver ID which will be assigned for the next registered driver.
    /// @return driverId The next driver ID.
    function nextDriverId() public view returns (uint32 driverId) {
        return _dripsStorage().nextDriverId;
    }

    /// @notice Returns the amount currently stored in the protocol of the given token.
    /// The sum of streaming and splitting balances can never exceed `MAX_TOTAL_BALANCE`.
    /// The amount of tokens held by the Drips contract exceeding the sum of
    /// streaming and splitting balances can be `withdraw`n.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return streamsBalance The balance currently stored in streaming.
    /// @return splitsBalance The balance currently stored in splitting.
    function balances(IERC20 erc20)
        public
        view
        returns (uint128 streamsBalance, uint128 splitsBalance)
    {
        Balance storage balance = _dripsStorage().balances[erc20];
        return (balance.streams, balance.splits);
    }

    /// @notice Increases the balance of the given token currently stored in streams.
    /// No funds are transferred, all the tokens are expected to be already held by Drips.
    /// The new total balance is verified to have coverage in the held tokens
    /// and to be within the limit of `MAX_TOTAL_BALANCE`.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The amount to increase the streams balance by.
    function _increaseStreamsBalance(IERC20 erc20, uint128 amt) internal {
        _verifyBalanceIncrease(erc20, amt);
        _dripsStorage().balances[erc20].streams += amt;
    }

    /// @notice Decreases the balance of the given token currently stored in streams.
    /// No funds are transferred, but the tokens held by Drips
    /// above the total balance become withdrawable.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The amount to decrease the streams balance by.
    function _decreaseStreamsBalance(IERC20 erc20, uint128 amt) internal {
        _dripsStorage().balances[erc20].streams -= amt;
    }

    /// @notice Increases the balance of the given token currently stored in streams.
    /// No funds are transferred, all the tokens are expected to be already held by Drips.
    /// The new total balance is verified to have coverage in the held tokens
    /// and to be within the limit of `MAX_TOTAL_BALANCE`.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The amount to increase the streams balance by.
    function _increaseSplitsBalance(IERC20 erc20, uint128 amt) internal {
        _verifyBalanceIncrease(erc20, amt);
        _dripsStorage().balances[erc20].splits += amt;
    }

    /// @notice Decreases the balance of the given token currently stored in splits.
    /// No funds are transferred, but the tokens held by Drips
    /// above the total balance become withdrawable.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The amount to decrease the splits balance by.
    function _decreaseSplitsBalance(IERC20 erc20, uint128 amt) internal {
        _dripsStorage().balances[erc20].splits -= amt;
    }

    /// @notice Moves the balance of the given token currently stored in streams to splits.
    /// No funds are transferred, all the tokens are already held by Drips.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The amount to decrease the splits balance by.
    function _moveBalanceFromStreamsToSplits(IERC20 erc20, uint128 amt) internal {
        Balance storage balance = _dripsStorage().balances[erc20];
        balance.streams -= amt;
        balance.splits += amt;
    }

    /// @notice Verifies that the balance of streams or splits can be increased by the given amount.
    /// The sum of streaming and splitting balances is checked to not exceed
    /// `MAX_TOTAL_BALANCE` or the amount of tokens held by the Drips.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The amount to increase the streams or splits balance by.
    function _verifyBalanceIncrease(IERC20 erc20, uint128 amt) internal view {
        (uint256 streamsBalance, uint128 splitsBalance) = balances(erc20);
        uint256 newTotalBalance = streamsBalance + splitsBalance + amt;
        require(newTotalBalance <= MAX_TOTAL_BALANCE, "Total balance too high");
        require(newTotalBalance <= _tokenBalance(erc20), "Token balance too low");
    }

    /// @notice Transfers withdrawable funds to an address.
    /// The withdrawable funds are held by the Drips contract,
    /// but not used in the protocol, so they are free to be transferred out.
    /// Anybody can call `withdraw`, so all withdrawable funds should be withdrawn
    /// or used in the protocol before any 3rd parties have a chance to do that.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param receiver The address to send withdrawn funds to.
    /// @param amt The withdrawn amount.
    /// It must be at most the difference between the balance of the token held by the Drips
    /// contract address and the sum of balances managed by the protocol as indicated by `balances`.
    function withdraw(IERC20 erc20, address receiver, uint256 amt) public {
        (uint128 streamsBalance, uint128 splitsBalance) = balances(erc20);
        uint256 withdrawable = _tokenBalance(erc20) - streamsBalance - splitsBalance;
        require(amt <= withdrawable, "Withdrawal amount too high");
        emit Withdrawn(erc20, receiver, amt);
        erc20.safeTransfer(receiver, amt);
    }

    function _tokenBalance(IERC20 erc20) internal view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    /// @notice Counts cycles from which streams can be collected.
    /// This function can be used to detect that there are
    /// too many cycles to analyze in a single transaction.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return cycles The number of cycles which can be flushed
    function receivableStreamsCycles(uint256 accountId, IERC20 erc20)
        public
        view
        returns (uint32 cycles)
    {
        return Streams._receivableStreamsCycles(accountId, erc20);
    }

    /// @notice Calculate effects of calling `receiveStreams` with the given parameters.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param maxCycles The maximum number of received streams cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivableAmt The amount which would be received
    function receiveStreamsResult(uint256 accountId, IERC20 erc20, uint32 maxCycles)
        public
        view
        returns (uint128 receivableAmt)
    {
        (receivableAmt,,,,) = Streams._receiveStreamsResult(accountId, erc20, maxCycles);
    }

    /// @notice Receive streams for the account.
    /// Received streams cycles won't need to be analyzed ever again.
    /// Calling this function does not collect but makes the funds ready to be split and collected.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param maxCycles The maximum number of received streams cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivedAmt The received amount
    function receiveStreams(uint256 accountId, IERC20 erc20, uint32 maxCycles)
        public
        whenNotPaused
        returns (uint128 receivedAmt)
    {
        receivedAmt = Streams._receiveStreams(accountId, erc20, maxCycles);
        if (receivedAmt != 0) {
            _moveBalanceFromStreamsToSplits(erc20, receivedAmt);
            Splits._addSplittable(accountId, erc20, receivedAmt);
        }
    }

    /// @notice Receive streams from the currently running cycle from a single sender.
    /// It doesn't receive streams from the finished cycles, to do that use `receiveStreams`.
    /// Squeezed funds won't be received in the next calls to `squeezeStreams` or `receiveStreams`.
    /// Only funds streamed before `block.timestamp` can be squeezed.
    /// @param accountId The ID of the account receiving streams to squeeze funds for.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param senderId The ID of the streaming account to squeeze funds from.
    /// @param historyHash The sender's history hash that was valid right before
    /// they set up the sequence of configurations described by `streamsHistory`.
    /// @param streamsHistory The sequence of the sender's streams configurations.
    /// It can start at an arbitrary past configuration, but must describe all the configurations
    /// which have been used since then including the current one, in the chronological order.
    /// Only streams described by `streamsHistory` will be squeezed.
    /// If `streamsHistory` entries have no receivers, they won't be squeezed.
    /// @return amt The squeezed amount.
    function squeezeStreams(
        uint256 accountId,
        IERC20 erc20,
        uint256 senderId,
        bytes32 historyHash,
        StreamsHistory[] memory streamsHistory
    ) public whenNotPaused returns (uint128 amt) {
        amt = Streams._squeezeStreams(accountId, erc20, senderId, historyHash, streamsHistory);
        if (amt != 0) {
            _moveBalanceFromStreamsToSplits(erc20, amt);
            Splits._addSplittable(accountId, erc20, amt);
        }
    }

    /// @notice Calculate effects of calling `squeezeStreams` with the given parameters.
    /// See its documentation for more details.
    /// @param accountId The ID of the account receiving streams to squeeze funds for.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param senderId The ID of the streaming account to squeeze funds from.
    /// @param historyHash The sender's history hash that was valid right before `streamsHistory`.
    /// @param streamsHistory The sequence of the sender's streams configurations.
    /// @return amt The squeezed amount.
    function squeezeStreamsResult(
        uint256 accountId,
        IERC20 erc20,
        uint256 senderId,
        bytes32 historyHash,
        StreamsHistory[] memory streamsHistory
    ) public view returns (uint128 amt) {
        (amt,,,,) =
            Streams._squeezeStreamsResult(accountId, erc20, senderId, historyHash, streamsHistory);
    }

    /// @notice Returns account's received but not split yet funds.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return amt The amount received but not split yet.
    function splittable(uint256 accountId, IERC20 erc20) public view returns (uint128 amt) {
        return Splits._splittable(accountId, erc20);
    }

    /// @notice Calculate the result of splitting an amount using the current splits configuration.
    /// @param accountId The account ID.
    /// @param currReceivers The list of the account's current splits receivers.
    /// It must be exactly the same as the last list set for the account with `setSplits`.
    /// @param amount The amount being split.
    /// @return collectableAmt The amount made collectable for the account
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the account's splits receivers
    function splitResult(uint256 accountId, SplitsReceiver[] memory currReceivers, uint128 amount)
        public
        view
        returns (uint128 collectableAmt, uint128 splitAmt)
    {
        return Splits._splitResult(accountId, currReceivers, amount);
    }

    /// @notice Splits the account's splittable funds among receivers.
    /// The entire splittable balance of the given ERC-20 token is split.
    /// All split funds are split using the current splits configuration.
    /// Because the account can update their splits configuration at any time,
    /// it is possible that calling this function will be frontrun,
    /// and all the splittable funds will become splittable only using the new configuration.
    /// The account must be trusted with how funds sent to them will be splits,
    /// in the end they can do with their funds whatever they want by changing the configuration.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param currReceivers The list of the account's current splits receivers.
    /// It must be exactly the same as the last list set for the account with `setSplits`.
    /// @return collectableAmt The amount made collectable for the account
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the account's splits receivers
    function split(uint256 accountId, IERC20 erc20, SplitsReceiver[] memory currReceivers)
        public
        whenNotPaused
        returns (uint128 collectableAmt, uint128 splitAmt)
    {
        return Splits._split(accountId, erc20, currReceivers);
    }

    /// @notice Returns account's received funds already split and ready to be collected.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return amt The collectable amount.
    function collectable(uint256 accountId, IERC20 erc20) public view returns (uint128 amt) {
        return Splits._collectable(accountId, erc20);
    }

    /// @notice Collects account's received already split funds and makes them withdrawable.
    /// Anybody can call `withdraw`, so all withdrawable funds should be withdrawn
    /// or used in the protocol before any 3rd parties have a chance to do that.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return amt The collected amount
    function collect(uint256 accountId, IERC20 erc20)
        public
        whenNotPaused
        onlyDriver(accountId)
        returns (uint128 amt)
    {
        amt = Splits._collect(accountId, erc20);
        if (amt != 0) _decreaseSplitsBalance(erc20, amt);
    }

    /// @notice Gives funds from the account to the receiver.
    /// The receiver can split and collect them immediately.
    /// Requires that the tokens used to give are already sent to Drips and are withdrawable.
    /// Anybody can call `withdraw`, so all withdrawable funds should be withdrawn
    /// or used in the protocol before any 3rd parties have a chance to do that.
    /// @param accountId The account ID.
    /// @param receiver The receiver account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param amt The given amount
    function give(uint256 accountId, uint256 receiver, IERC20 erc20, uint128 amt)
        public
        whenNotPaused
        onlyDriver(accountId)
    {
        if (amt != 0) _increaseSplitsBalance(erc20, amt);
        Splits._give(accountId, receiver, erc20, amt);
    }

    /// @notice Current account streams state.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @return streamsHash The current streams receivers list hash, see `hashStreams`
    /// @return streamsHistoryHash The current streams history hash, see `hashStreamsHistory`.
    /// @return updateTime The time when streams have been configured for the last time.
    /// @return balance The balance when streams have been configured for the last time.
    /// @return maxEnd The current maximum end time of streaming.
    function streamsState(uint256 accountId, IERC20 erc20)
        public
        view
        returns (
            bytes32 streamsHash,
            bytes32 streamsHistoryHash,
            uint32 updateTime,
            uint128 balance,
            uint32 maxEnd
        )
    {
        return Streams._streamsState(accountId, erc20);
    }

    /// @notice The account's streams balance at the given timestamp.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param currReceivers The current streams receivers list.
    /// It must be exactly the same as the last list set for the account with `setStreams`.
    /// @param timestamp The timestamps for which balance should be calculated.
    /// It can't be lower than the timestamp of the last call to `setStreams`.
    /// If it's bigger than `block.timestamp`, then it's a prediction assuming
    /// that `setStreams` won't be called before `timestamp`.
    /// @return balance The account balance on `timestamp`
    function balanceAt(
        uint256 accountId,
        IERC20 erc20,
        StreamReceiver[] memory currReceivers,
        uint32 timestamp
    ) public view returns (uint128 balance) {
        return Streams._balanceAt(accountId, erc20, currReceivers, timestamp);
    }

    /// @notice Sets the account's streams configuration.
    /// Requires that the tokens used to increase the streams balance
    /// are already sent to Drips and are withdrawable.
    /// If the streams balance is decreased, the released tokens become withdrawable.
    /// Anybody can call `withdraw`, so all withdrawable funds should be withdrawn
    /// or used in the protocol before any 3rd parties have a chance to do that.
    /// @param accountId The account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param currReceivers The current streams receivers list.
    /// It must be exactly the same as the last list set for the account with `setStreams`.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The streams balance change to be applied.
    /// Positive to add funds to the streams balance, negative to remove them.
    /// @param newReceivers The list of the streams receivers of the account to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @param maxEndHint1 An optional parameter allowing gas optimization, pass `0` to ignore it.
    /// The first hint for finding the maximum end time when all streams stop due to funds
    /// running out after the balance is updated and the new receivers list is applied.
    /// Hints have no effect on the results of calling this function, except potentially saving gas.
    /// Hints are Unix timestamps used as the starting points for binary search for the time
    /// when funds run out in the range of timestamps from the current block's to `2^32`.
    /// Hints lower than the current timestamp are ignored.
    /// You can provide zero, one or two hints. The order of hints doesn't matter.
    /// Hints are the most effective when one of them is lower than or equal to
    /// the last timestamp when funds are still streamed, and the other one is strictly larger
    /// than that timestamp,the smaller the difference between such hints, the higher gas savings.
    /// The savings are the highest possible when one of the hints is equal to
    /// the last timestamp when funds are still streamed, and the other one is larger by 1.
    /// It's worth noting that the exact timestamp of the block in which this function is executed
    /// may affect correctness of the hints, especially if they're precise.
    /// Hints don't provide any benefits when balance is not enough to cover
    /// a single second of streaming or is enough to cover all streams until timestamp `2^32`.
    /// Even inaccurate hints can be useful, and providing a single hint
    /// or two hints that don't enclose the time when funds run out can still save some gas.
    /// Providing poor hints that don't reduce the number of binary search steps
    /// may cause slightly higher gas usage than not providing any hints.
    /// @param maxEndHint2 An optional parameter allowing gas optimization, pass `0` to ignore it.
    /// The second hint for finding the maximum end time, see `maxEndHint1` docs for more details.
    /// @return realBalanceDelta The actually applied streams balance change.
    /// If it's lower than zero, it's the negative of the amount that became withdrawable.
    function setStreams(
        uint256 accountId,
        IERC20 erc20,
        StreamReceiver[] memory currReceivers,
        int128 balanceDelta,
        StreamReceiver[] memory newReceivers,
        // slither-disable-next-line similar-names
        uint32 maxEndHint1,
        uint32 maxEndHint2
    ) public whenNotPaused onlyDriver(accountId) returns (int128 realBalanceDelta) {
        if (balanceDelta > 0) _increaseStreamsBalance(erc20, uint128(balanceDelta));
        realBalanceDelta = Streams._setStreams(
            accountId, erc20, currReceivers, balanceDelta, newReceivers, maxEndHint1, maxEndHint2
        );
        if (realBalanceDelta < 0) _decreaseStreamsBalance(erc20, uint128(-realBalanceDelta));
    }

    /// @notice Calculates the hash of the streams configuration.
    /// It's used to verify if streams configuration is the previously set one.
    /// @param receivers The list of the streams receivers.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// If the streams have never been updated, pass an empty array.
    /// @return streamsHash The hash of the streams configuration
    function hashStreams(StreamReceiver[] memory receivers)
        public
        pure
        returns (bytes32 streamsHash)
    {
        return Streams._hashStreams(receivers);
    }

    /// @notice Calculates the hash of the streams history
    /// after the streams configuration is updated.
    /// @param oldStreamsHistoryHash The history hash
    /// that was valid before the streams were updated.
    /// The `streamsHistoryHash` of the account before they set streams for the first time is `0`.
    /// @param streamsHash The hash of the streams receivers being set.
    /// @param updateTime The timestamp when the streams were updated.
    /// @param maxEnd The maximum end of the streams being set.
    /// @return streamsHistoryHash The hash of the updated streams history.
    function hashStreamsHistory(
        bytes32 oldStreamsHistoryHash,
        bytes32 streamsHash,
        uint32 updateTime,
        uint32 maxEnd
    ) public pure returns (bytes32 streamsHistoryHash) {
        return Streams._hashStreamsHistory(oldStreamsHistoryHash, streamsHash, updateTime, maxEnd);
    }

    /// @notice Sets the account splits configuration.
    /// The configuration is common for all ERC-20 tokens.
    /// Nothing happens to the currently splittable funds, but when they are split
    /// after this function finishes, the new splits configuration will be used.
    /// Because anybody can call `split`, calling this function may be frontrun
    /// and all the currently splittable funds will be split using the old splits configuration.
    /// @param accountId The account ID.
    /// @param receivers The list of the account's splits receivers to be set.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the account.
    /// If the sum of weights of all receivers is less than `_TOTAL_SPLITS_WEIGHT`,
    /// some funds won't be split, but they will be left for the account to collect.
    /// It's valid to include the account's own `accountId` in the list of receivers,
    /// but funds split to themselves return to their splittable balance and are not collectable.
    /// This is usually unwanted, because if splitting is repeated,
    /// funds split to themselves will be again split using the current configuration.
    /// Splitting 100% to self effectively blocks splitting unless the configuration is updated.
    function setSplits(uint256 accountId, SplitsReceiver[] memory receivers)
        public
        whenNotPaused
        onlyDriver(accountId)
    {
        Splits._setSplits(accountId, receivers);
    }

    /// @notice Current account's splits hash, see `hashSplits`.
    /// @param accountId The account ID.
    /// @return currSplitsHash The current account's splits hash
    function splitsHash(uint256 accountId) public view returns (bytes32 currSplitsHash) {
        return Splits._splitsHash(accountId);
    }

    /// @notice Calculates the hash of the list of splits receivers.
    /// @param receivers The list of the splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// @return receiversHash The hash of the list of splits receivers.
    function hashSplits(SplitsReceiver[] memory receivers)
        public
        pure
        returns (bytes32 receiversHash)
    {
        return Splits._hashSplits(receivers);
    }

    /// @notice Emits account metadata.
    /// The keys and the values are not standardized by the protocol, it's up to the users
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @param accountId The account ID.
    /// @param accountMetadata The list of account metadata.
    function emitAccountMetadata(uint256 accountId, AccountMetadata[] calldata accountMetadata)
        public
        whenNotPaused
        onlyDriver(accountId)
    {
        unchecked {
            for (uint256 i = 0; i < accountMetadata.length; i++) {
                AccountMetadata calldata metadata = accountMetadata[i];
                emit AccountMetadataEmitted(accountId, metadata.key, metadata.value);
            }
        }
    }

    /// @notice Returns the Drips storage.
    /// @return storageRef The storage.
    function _dripsStorage() internal view returns (DripsStorage storage storageRef) {
        bytes32 slot = _dripsStorageSlot;
        // slither-disable-next-line assembly
        assembly {
            storageRef.slot := slot
        }
    }
}