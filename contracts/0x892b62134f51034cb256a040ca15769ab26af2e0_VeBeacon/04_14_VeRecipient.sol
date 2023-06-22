// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import {CrossChainEnabled} from "openzeppelin-contracts/contracts/crosschain/CrossChainEnabled.sol";

import "./base/Structs.sol";
import {BoringOwnable} from "./base/BoringOwnable.sol";

/// @title VeRecipient
/// @author zefram.eth
/// @notice Recipient on non-Ethereum networks that receives data from the Ethereum beacon
/// and makes vetoken balances available on this network.
abstract contract VeRecipient is CrossChainEnabled, BoringOwnable {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error VeRecipient__InvalidInput();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event UpdateVeBalance(address indexed user);
    event SetBeacon(address indexed newBeacon);

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 internal constant MAX_ITERATIONS = 255;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    address public beacon;
    mapping(address => Point) public userData;
    Point public globalData;
    mapping(uint256 => int128) public slopeChanges;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address beacon_, address owner_) BoringOwnable(owner_) {
        beacon = beacon_;
        emit SetBeacon(beacon_);
    }

    /// -----------------------------------------------------------------------
    /// Crosschain functions
    /// -----------------------------------------------------------------------

    /// @notice Called by VeBeacon from Ethereum via bridge to update vetoken balance & supply info.
    function updateVeBalance(
        address user,
        int128 userBias,
        int128 userSlope,
        uint256 userTs,
        int128 globalBias,
        int128 globalSlope,
        uint256 globalTs,
        SlopeChange[] calldata slopeChanges_
    ) external onlyCrossChainSender(beacon) {
        userData[user] = Point({bias: userBias, slope: userSlope, ts: userTs});
        globalData = Point({bias: globalBias, slope: globalSlope, ts: globalTs});

        uint256 slopeChangesLength = slopeChanges_.length;
        for (uint256 i; i < slopeChangesLength;) {
            slopeChanges[slopeChanges_[i].ts] = slopeChanges_[i].change;

            unchecked {
                ++i;
            }
        }

        emit UpdateVeBalance(user);
    }

    /// -----------------------------------------------------------------------
    /// Owner functions
    /// -----------------------------------------------------------------------

    /// @notice Called by owner to update the beacon address.
    /// @dev The beacon address needs to be updateable because VeBeacon needs to be redeployed
    /// when support for a new network is added.
    /// @param newBeacon The new address
    function setBeacon(address newBeacon) external onlyOwner {
        if (newBeacon == address(0)) revert VeRecipient__InvalidInput();
        beacon = newBeacon;
        emit SetBeacon(newBeacon);
    }

    /// -----------------------------------------------------------------------
    /// View functions
    /// -----------------------------------------------------------------------

    /// @notice Computes the vetoken balance of a user. Returns 0 if the user's data hasn't
    /// been broadcasted from VeBeacon. Exhibits the same time-decay behavior as regular
    /// VotingEscrow contracts.
    /// @param user The user address to query
    /// @return The user's vetoken balance.
    function balanceOf(address user) external view returns (uint256) {
        // storage loads
        Point memory u = userData[user];

        // compute vetoken balance
        int256 veBalance = u.bias - u.slope * int128(int256(block.timestamp - u.ts));
        if (veBalance < 0) veBalance = 0;
        return uint256(veBalance);
    }

    /// @notice Computes the total supply of the vetoken. Returns 0 if data hasn't
    /// been broadcasted from VeBeacon. Exhibits the same time-decay behavior as regular
    /// VotingEscrow contracts.
    /// @dev The value may diverge from the correct value if `updateVeBalance()` hasn't been
    /// called for 8 consecutive epochs (~2 months). This is because we limit the size of each
    /// slopeChanges update to limit gas costs.
    /// @return The vetoken's total supply
    function totalSupply() external view returns (uint256) {
        Point memory g = globalData;
        uint256 ti = (g.ts / (1 weeks)) * (1 weeks);
        for (uint256 i; i < MAX_ITERATIONS;) {
            ti += 1 weeks;
            int128 slopeChange;
            if (ti > block.timestamp) {
                ti = block.timestamp;
            } else {
                slopeChange = slopeChanges[ti];
            }
            g.bias -= g.slope * int128(int256(ti - g.ts));
            if (ti == block.timestamp) break;
            g.slope += slopeChange;
            g.ts = ti;

            unchecked {
                ++i;
            }
        }

        if (g.bias < 0) g.bias = 0;
        return uint256(uint128(g.bias));
    }

    /// @notice Returns the timestamp a user's vetoken position was last updated. Returns 0 if the user's data
    /// has never been broadcasted.
    /// @dev Added for compatibility with kick() in gauge contracts.
    /// @param user The user's address
    /// @return The last update timestamp
    function user_point_history__ts(address user, uint256 /*epoch*/ ) external view returns (uint256) {
        return userData[user].ts;
    }

    /// @notice Just returns 0.
    /// @dev Added for compatibility with kick() in gauge contracts.
    function user_point_epoch(address /*user*/ ) external pure returns (uint256) {
        return 0;
    }
}