// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title ITierV2
/// @notice `ITierV2` is a simple interface that contracts can implement to
/// provide membership lists for other contracts.
///
/// There are many use-cases for a time-preserving conditional membership list.
///
/// Some examples include:
///
/// - Self-serve whitelist to participate in fundraising
/// - Lists of users who can claim airdrops and perks
/// - Pooling resources with implied governance/reward tiers
/// - POAP style attendance proofs allowing access to future exclusive events
///
/// @dev Standard interface to a tiered membership.
///
/// A "membership" can represent many things:
/// - Exclusive access.
/// - Participation in some event or process.
/// - KYC completion.
/// - Combination of sub-memberships.
/// - Etc.
///
/// The high level requirements for a contract implementing `ITierV2`:
/// - MUST represent held tiers as a `uint`.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the time each tier has
///     been continuously held since encoded as `uint32`.
///   - The encoded tiers start at `1`; Tier `0` is implied if no tier has ever
///     been held.
///   - Tier `0` is NOT encoded in the report, it is simply the fallback value.
///   - If a tier is lost the time data is erased for that tier and will be
///     set if/when the tier is regained to the new time.
///   - If a tier is held but the historical time information is not available
///     the report MAY return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
///   - Context can be a list of numbers that MAY pairwise define tiers such as
///     minimum thresholds, or MAY simply provide global context such as a
///     relevant NFT ID for example.
/// - MUST implement `reportTimeForTier`
///   - Functions exactly as `report` but only returns a single time for a
///     single tier
///   - MUST return the same time value `report` would for any given tier and
///     context combination.
///
/// So the four possible states and report values are:
/// - Tier is held and time is known: Timestamp is in the report
/// - Tier is held but time is NOT known: `0` is in the report
/// - Tier is NOT held: `0xFF..` is in the report
/// - Tier is unknown: `0xFF..` is in the report
///
/// The reason `context` is specified as a list of values rather than arbitrary
/// bytes is to allow clear and efficient compatibility with VM stacks. Some N
/// values can be taken from a VM stack and used directly as a context, which
/// would be difficult or impossible to ensure is safe for arbitrary bytes.
interface ITierV2 {
    /// Same as report but only returns the time for a single tier.
    /// Often the implementing contract can calculate a single tier more
    /// efficiently than all 8 tiers. If the consumer only needs one or a few
    /// tiers it MAY be much cheaper to request only those tiers individually.
    /// This DOES NOT apply to all contracts, an obvious example is token
    /// balance based tiers which always return `ALWAYS` or `NEVER` for all
    /// tiers so no efficiency is gained.
    /// The return value is a `uint256` for gas efficiency but the values will
    /// be bounded by `type(uint32).max` as no single tier can report a value
    /// higher than this.
    function reportTimeForTier(
        address account,
        uint256 tier,
        uint256[] calldata context
    ) external view returns (uint256 time);

    /// Same as `ITier` but with a list of values for `context` which allows a
    /// single underlying state to present many different reports dynamically.
    ///
    /// For example:
    /// - Staking ledgers can calculate different tier thresholds
    /// - NFTs can give different tiers based on different IDs
    /// - Snapshot ERC20s can give different reports based on snapshot ID
    ///
    /// `context` supercedes `setTier` function and `TierChange` event from
    /// `ITier` at the interface level.
    function report(address account, uint256[] calldata context)
        external
        view
        returns (uint256 report);
}