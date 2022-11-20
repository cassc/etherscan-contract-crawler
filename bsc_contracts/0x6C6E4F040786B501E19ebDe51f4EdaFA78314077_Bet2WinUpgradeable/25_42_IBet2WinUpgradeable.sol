// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IAuthority.sol";
import "../internal-upgradeable/interfaces/ISignableUpgradeable.sol";
import "../internal-upgradeable/interfaces/IFundForwarderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Bet2Win interface for Bet2Win contract
/// @notice Contains Bet2Win Interface for contract interaction
interface IBet2WinUpgradeable is ISignableUpgradeable {
    struct Payment {
        address referrer;
        uint8 v;
        uint256 deadline;
        uint256 amount;
        address token;
        bytes32 r;
        bytes32 s;
    }

    event ReferreeAdded(address indexed user, address indexed referree);

    event BetPlaced(
        address indexed user,
        uint256 indexed id,
        uint256 indexed side,
        uint256 sideAgainst,
        uint256 odd,
        uint256 usdAmt
    );

    event BetSettled(
        address indexed to,
        uint256 indexed id,
        uint256 side,
        uint256 indexed receiptId,
        uint256 received
    );

    event MatchResolved(
        uint256 indexed gameId,
        uint256 indexed matchId,
        uint256 indexed status
    );

    /// @notice Update referree of a user
    /// @dev Caller must be croupier, referree address should not be blacklisted or contract address
    // function addReferree(address user_, address referree_) external;

    /// @notice Reveal which team won
    /// @dev Caller must be croupier, sideInFavor_ must not be 0 (default value)
    /// @param sideInFavor_ A number indexing a team in the match which won
    //         status_  Current state of the match, i.e FIRST_HALF, FULL_TIME, SECOND_HALF
    // function resolveMatch(
    //     uint256 gameId_,
    //     uint256 matchId_,
    //     uint256 status_,
    //     uint256 sideInFavor_
    // ) external;

    /// @notice Bet placing transaction
    /// @dev Caller is gamblers, not blacklisted, not proxy call
    /// @param betId_   A unique number from represent the encoded data from gameId, matchId, odd, settleStatus, side
    ///        amount_  Bet size
    // function placeBet(
    //     uint256 betId_,
    //     uint96 amount_,
    //     uint256 permitDeadline_,
    //     uint256 croupierDeadline_,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s,
    //     IERC20Upgradeable paymentToken_,
    //     bytes calldata croupierSignature_
    // ) external payable;

    /// @notice Users claim bet rewards if they are eligible
    /// @dev Caller is gamblers, not blacklisted, not proxy call
    // function settleBet(
    //     uint256 gameId_,
    //     uint256 matchId_,
    //     uint256 status_
    // ) external;

    // function estimateRewardReceive(
    //     address user_,
    //     bool isNativePayment_,
    //     uint256 betSize_,
    //     uint256 odd_
    // ) external view returns (uint256);

    /// @notice Get all users for offchain filtering
    /// @return All users that have already placed bet
    //function users() external view returns (address[] memory);

    /// @notice Get bet data of specific match
    /// @return Struct bet containing bet info
    // function betOf(
    //     address gambler_,
    //     uint256 gameId_,
    //     uint256 matchId_
    // ) external view returns (Bet memory);

    //function matchesIds(uint8 gameId_) external view returns (uint256[] memory);

    //function gameIds() external view returns (uint256[] memory);

    /// @notice Encode bet data into a unique number
    /// @dev Input data must be in range of 48 bits
    /// @return betId   Unique key representing bet data
    // function betIdOf(
    //     uint256 gameId_,
    //     uint256 matchId_,
    //     uint256 odd_,
    //     uint256 settleStatus_,
    //     uint256 side_
    // ) external pure returns (uint256);

    /// @notice Create a unique from gameId_ and matchId_ for indexing
    /// @dev Params must stay in range of 48 bits
    /// @return key Unique key from gameId_, matchId_
    // function key(uint256 gameId_, uint256 matchId_)
    //     external
    //     pure
    //     returns (uint256);
}