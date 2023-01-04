// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Tier} from "./Tier.sol";

/// @param goal Target amount to raise. If a raise meets its goal amount, the
/// raise settles as Funded, users keep their tokens, and the owner may withdraw
/// the collected funds. If a raise fails to meet its goual the raise settles as
/// Cancelled and users may redeem their tokens for a refund.
/// @param max Maximum amount to raise.
/// @param presaleStart Start timestamp of the presale phase. During this phase,
/// allowlisted users may mint tokens by providing a Merkle proof.
/// @param presaleEnd End timestamp of the presale phase.
/// @param publicSaleStart Start timestamp of the public sale phase. During this
/// phase, any user may mint a token.
/// @param publicSaleEnd End timestamp of the public sale phase.
/// @param currency Currency for this raise, either an ERC20 token address, or
/// the "dolphin address" for ETH. ERC20 tokens must be allowed by TokenAuth.
struct RaiseParams {
    uint256 goal;
    uint256 max;
    uint64 presaleStart;
    uint64 presaleEnd;
    uint64 publicSaleStart;
    uint64 publicSaleEnd;
    address currency;
}

/// @notice A raise may be in one of three states, depending on whether it has
/// ended and has or has not met its goal:
/// - An Active raise has not yet ended.
/// - A Funded raise has ended and met its goal.
/// - A Cancelled raise has ended and either did not meet its goal or was
///   cancelled by the raise creator.
enum RaiseState {
    Active,
    Funded,
    Cancelled
}

/// @param goal Target amount to raise. If a raise meets its goal amount, the
/// raise settles as Funded, users keep their tokens, and the owner may withdraw
/// the collected funds. If a raise fails to meet its goual the raise settles as
/// Cancelled and users may redeem their tokens for a refund.
/// @param max Maximum amount to raise.
/// @param timestamps Struct containing presale and public sale start/end times.
/// @param currency Currency for this raise, either an ERC20 token address, or
/// the "dolphin address" for ETH. ERC20 tokens must be allowed by TokenAuth.
/// @param state State of the raise. All new raises begin in Active state.
/// @param projectId Integer ID of the project associated with this raise.
/// @param raiseId Integer ID of this raise.
/// @param tokens Struct containing addresses of this raise's tokens.
/// @param feeSchedule Struct containing fee schedule for this raise.
/// @param raised Total amount of ETH or ERC20 token contributed to this raise.
/// @param balance Creator's share of the total amount raised.
/// @param fees Protocol fees from this raise. raised = balance + fees
struct Raise {
    uint256 goal;
    uint256 max;
    RaiseTimestamps timestamps;
    address currency;
    RaiseState state;
    uint32 projectId;
    uint32 raiseId;
    RaiseTokens tokens;
    FeeSchedule feeSchedule;
    uint256 raised;
    uint256 balance;
    uint256 fees;
}

/// @param presaleStart Start timestamp of the presale phase. During this phase,
/// allowlisted users may mint tokens by providing a Merkle proof.
/// @param presaleEnd End timestamp of the presale phase.
/// @param publicSaleStart Start timestamp of the public sale phase. During this
/// phase, any user may mint a token.
/// @param publicSaleEnd End timestamp of the public sale phase.
struct RaiseTimestamps {
    uint64 presaleStart;
    uint64 presaleEnd;
    uint64 publicSaleStart;
    uint64 publicSaleEnd;
}

/// @param fanToken Address of this raise's ERC1155 fan token.
/// @param brandToken Address of this raise's ERC1155 brand token.
struct RaiseTokens {
    address fanToken;
    address brandToken;
}

/// @param fanFee Protocol fee in basis points for fan token sales.
/// @param brandFee Protocol fee in basis poitns for brand token sales.
struct FeeSchedule {
    uint16 fanFee;
    uint16 brandFee;
}

/// @notice A raise may be in one of four phases, depending on the timestamps of
/// its presale and public sale phases:
/// - A Scheduled raise is not open for minting. If a raise is Scheduled, it is
/// currently either before the Presale phase or between Presale and PublicSale.
/// - The Presale phase is between the presale start and presale end timestamps.
/// - The PublicSale phase is between the public sale start and public sale end
/// timestamps. PublicSale must be after Presale, but the raise may return to
/// the Scheduled phase in between.
/// - After the public sale end timestamp, the raise has Ended.
enum Phase {
    Scheduled,
    Presale,
    PublicSale,
    Ended
}