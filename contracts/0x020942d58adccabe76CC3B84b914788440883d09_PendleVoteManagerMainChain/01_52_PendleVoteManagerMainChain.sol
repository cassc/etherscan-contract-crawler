// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PendleVoteManagerBaseUpg} from"./PendleVoteManagerBaseUpg.sol";

import "../interfaces/IPendleStaking.sol";
import "../interfaces/pendle/IPVotingEscrowMainchain.sol";
import "../libraries/math/Math.sol";
import "../interfaces/IVLPenpie.sol";
import "../interfaces/pendle/IPVoteController.sol";

/// @title PendleVoteManagerMainChain (for Ethereum where vePendle lives)
/// @notice PendleVoteManagerMainChain on Ethereum will store all voting information, which should be aggregated one vote cast from PendleVoteManagerSideChain (remote chain .
///         So the voting information here represents penpie's all voting information.
///
///         PendleVoteManagerSideChain acts like a delegated vote which stores only voting information on that chain, and will have to cast to PendleVoteManageMainChain on Ethereum
///         then later to be casted to Pendle.
///
///         VoteManagerSubChain --(cross chain cast vote)--> VoteManagerMainChain --(cast vote)--> Pendle
/// @author Magpie Team

contract PendleVoteManagerMainChain is PendleVoteManagerBaseUpg {
    using SafeERC20 for IERC20;

    /* ============ Structs ============ */

    /* ============ State Variables ============ */

    uint64 constant PENDLE_USER_VOTE_MAX_WEIGHT = 1e18;

    IPVoteController public voter; // Pendle voter interface
    IPVotingEscrowMainchain public vePendle; //main contract interact with from pendle side

    mapping(address => bool) remotePendleVoter; // to stored address of remote vote manager.

    /* ============ Events ============ */

    event RemoteDelegateSet(address indexed _user, bool _allowed);
    event ReceiveRemoteCast(bool _isRemotePendleVoter);

    /* ============ Errors ============ */

    /* ============ Constructor ============ */

    constructor() {_disableInitializers();}

    function __PendleVoteManagerMainChain_init(
        IPVoteController _voter,
        IPVotingEscrowMainchain _vePendle,
        IPendleStaking _pendleStaking,
        address _vlPenpie,
        address _endpoint
    ) public initializer {
        __PendleVoteManagerBaseUpg_init(_pendleStaking, _vlPenpie, _endpoint);
        voter = _voter;
        vePendle = _vePendle;
    }

    /* ============ External Getters ============ */

    function totalVotes() public view returns (uint256) {
        return vePendle.balanceOf(address(pendleStaking));
    }

    function vePendlePerLockedPenpie() public view returns (uint256) {
        if (IVLPenpie(vlPenpie).totalLocked() == 0) return 0;
        return totalVotes() * 1e18 / IVLPenpie(vlPenpie).totalLocked();
    }

    function getVoteForMarket(address market) public view returns (uint256) {
        IPVoteController.UserPoolData memory userPoolData = voter
            .getUserPoolVote(address(pendleStaking), market);
        uint256 poolVote = (userPoolData.weight * totalVotes()) / 1e18;
        return poolVote;
    }

    function getVoteForMarkets(
        address[] calldata markets
    ) public view returns (uint256[] memory votes) {
        uint256 length = markets.length;
        votes = new uint256[](length);
        for (uint256 i; i < length; i++) {
            votes[i] = getVoteForMarket(markets[i]);
        }
    }

    function getUserVoteForMarketsInVlPenpie(
        address[] calldata _markets,
        address _user
    ) public view returns (uint256[] memory votes) {
        uint256 length = _markets.length;
        votes = new uint256[](length);
        for (uint256 i; i < length; i++) {
            votes[i] = userVotedForPoolInVlPenpie[_user][_markets[i]];
        }
    }

    /* ============ External Functions ============ */

    function isRemotePendleVoter(address _remotePendleVoter) external view returns(bool) {
        return remotePendleVoter[_remotePendleVoter];
    }

    /// @notice cast all pending votes
    /// @notice we're casting weights to Pendle Finance
    function manualVote(
        address[] calldata _pools,
        uint64[] calldata _weights
    ) external nonReentrant onlyOperator {
        lastCastTime = block.timestamp;
        IPendleStaking(pendleStaking).vote(_pools, _weights);
        emit VoteCasted(msg.sender, lastCastTime);
    }

    /// @notice cast all pending votes
    /// @notice we're casting weights to Pendle Finance
    // function castVotes() external nonReentrant whenNotPaused {
    //     lastCastTime = block.timestamp;
    //     uint256 length = poolInfos.length;

    //     address[] memory _pools = new address[](length);
    //     uint64[] memory votes = new uint64[](length);

    //     if (totalVlPenpieInVote > 0) {
    //         uint256 totalVlPnpInVote = 0;
    //         for (uint256 i; i < length; i++) {
    //             Pool storage pool = poolInfos[i];
    //             _pools[i] = pool.market;

    //             if (!pool.isActive) continue;
                
    //             totalVlPnpInVote += pool.totalVoteInVlPenpie;
    //         }

    //         for (uint256 i; i < length; i++) {
    //             Pool storage pool = poolInfos[i];
    //             _pools[i] = pool.market;

    //             if (!pool.isActive) continue;
                
    //             votes[i] = SafeCast.toUint64(pool.totalVoteInVlPenpie * PENDLE_USER_VOTE_MAX_WEIGHT / totalVlPnpInVote);
    //         }
    //     }
        
    //     IPendleStaking(pendleStaking).vote(_pools, votes);
    //     emit VoteCasted(msg.sender, lastCastTime);
    // }

    /* ============ Internal Functions ============ */

    /* ============ layerzero Functions ============ */

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (address user, UserVote[] memory userVotes) = decodeVote(_payload);

        emit ReceiveRemoteCast(remotePendleVoter[user]);

        if (remotePendleVoter[user])
            _recCast(user, userVotes);
    }

    function _recCast(address _user, UserVote[] memory _userVotes) internal {
        _updateVoteAndCheck(_user, _userVotes);
    }

    /* ============ Admin Functions ============ */

    function setRemoteDelegate(
        address _user,
        bool _allowed
    ) external onlyOwner {
        remotePendleVoter[_user] = _allowed;
        emit RemoteDelegateSet(_user, _allowed);
    }
}