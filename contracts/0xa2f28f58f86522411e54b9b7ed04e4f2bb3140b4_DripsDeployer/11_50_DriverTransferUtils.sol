// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {Drips, StreamReceiver, IERC20, SafeERC20} from "./Drips.sol";
import {ERC2771Context} from "openzeppelin-contracts/metatx/ERC2771Context.sol";

/// @notice ERC-20 token transfer utilities for drivers.
/// Encapsulates the logic for token transfers made by drivers implementing user identities.
/// All funds going into Drips are transferred ad-hoc from the caller (`msg.sender`),
/// and all funds going out of Drips are transferred in full to the provided address.
/// Compatible with `Caller` by supporting ERC-2771.
abstract contract DriverTransferUtils is ERC2771Context {
    /// @param forwarder The ERC-2771 forwarder to trust. May be the zero address.
    constructor(address forwarder) ERC2771Context(forwarder) {}

    /// @notice Returns the address of the Drips contract to use for ERC-20 transfers.
    function _drips() internal virtual returns (Drips);

    /// @notice Collects the account's received already split funds
    /// and transfers them out of the Drips contract.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param transferTo The address to send collected funds to
    /// @return amt The collected amount
    function _collectAndTransfer(uint256 accountId, IERC20 erc20, address transferTo)
        internal
        returns (uint128 amt)
    {
        amt = _drips().collect(accountId, erc20);
        if (amt > 0) _drips().withdraw(erc20, transferTo, amt);
    }

    /// @notice Gives funds from the message sender to the receiver.
    /// The receiver can split and collect them immediately.
    /// Transfers the funds to be given from the message sender's wallet to the Drips contract.
    /// @param receiver The receiver account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param amt The given amount
    function _giveAndTransfer(uint256 accountId, uint256 receiver, IERC20 erc20, uint128 amt)
        internal
    {
        if (amt > 0) _transferFromCaller(erc20, amt);
        _drips().give(accountId, receiver, erc20, amt);
    }

    /// @notice Sets the message sender's streams configuration.
    /// Transfers funds between the message sender's wallet and the Drips contract
    /// to fulfil the change of the streams balance.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param currReceivers The current streams receivers list.
    /// It must be exactly the same as the last list set for the sender with `setStreams`.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The streams balance change to be applied.
    /// Positive to add funds to the streams balance, negative to remove them.
    /// @param newReceivers The list of the streams receivers of the sender to be set.
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
    /// @param transferTo The address to send funds to in case of decreasing balance
    /// @return realBalanceDelta The actually applied streams balance change.
    function _setStreamsAndTransfer(
        uint256 accountId,
        IERC20 erc20,
        StreamReceiver[] calldata currReceivers,
        int128 balanceDelta,
        StreamReceiver[] calldata newReceivers,
        // slither-disable-next-line similar-names
        uint32 maxEndHint1,
        uint32 maxEndHint2,
        address transferTo
    ) internal returns (int128 realBalanceDelta) {
        if (balanceDelta > 0) _transferFromCaller(erc20, uint128(balanceDelta));
        realBalanceDelta = _drips().setStreams(
            accountId, erc20, currReceivers, balanceDelta, newReceivers, maxEndHint1, maxEndHint2
        );
        if (realBalanceDelta < 0) _drips().withdraw(erc20, transferTo, uint128(-realBalanceDelta));
    }

    /// @notice Transfers tokens from the sender to Drips.
    /// @param erc20 The used ERC-20 token.
    /// @param amt The transferred amount
    function _transferFromCaller(IERC20 erc20, uint128 amt) internal {
        SafeERC20.safeTransferFrom(erc20, _msgSender(), address(_drips()), amt);
    }
}