// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import {Initializable} from "openzeppelin/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "./OwnableUpgradeable.sol";

/* -------------------------------------------------------------------------- */
/*                                 interfaces                                 */
/* -------------------------------------------------------------------------- */
interface ISoftStaking {
    function setStaked(uint256 tokenID_, bool staked_) external;
}

interface IItem {
    function claim(address receiver_, uint8 itemType_) external;
}

/* -------------------------------------------------------------------------- */
/*                                    types                                   */
/* -------------------------------------------------------------------------- */
struct StakedTeam {
    uint256 tokenID;
    uint256 quirkling1;
    uint256 quirkling2;
    uint256 timestamp;
}

struct StakedQuirkies {
    address owner;
    uint256 timestamp;
}

struct StakedQuirklings {
    address owner;
    uint256 timestamp;
}

struct ClaimedItems {
    bool episode1;
    bool episode2;
    bool episode3;
    bool episode4;
}

struct Staker {
    // Need this bool to expose stakersMap as public
    // https://stackoverflow.com/questions/75045282/solidity-internal-or-recursive-type-is-not-allowed-for-public-state-variables
    bool isTrue;
    StakedTeam[] stakedTeams;
}

struct Team {
    uint256 quirkieTokenID;
    uint256 quirklingTokenID;
    uint256 quirklingTokenID2;
}

struct ClaimQuirkie {
    StakedTeam team;
    bool episode1;
    bool episode2;
    bool episode3;
    bool episode4;
}

/* -------------------------------------------------------------------------- */
/*                                   library                                  */
/* -------------------------------------------------------------------------- */
library QuestSeason2Storage {
    struct Layout {
        mapping(address => Staker) stakersMap;
        mapping(uint256 => StakedQuirkies) quirkiesStakedMap;
        mapping(uint256 => StakedQuirklings) quirklingsStakedMap;
        mapping(uint256 => ClaimedItems) quirkiesClaimedMap;
        mapping(uint256 => ClaimedItems) quirklingsClaimedMap;
        mapping(address => uint256) nonceMap;
        address signer;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quirkies.quest.season2.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/* -------------------------------------------------------------------------- */
/*                                    main                                    */
/* -------------------------------------------------------------------------- */
contract QuestSeason2ImplementationV1 is OwnableUpgradeable {
    using ECDSA for bytes32;

    /* -------------------------------------------------------------------------- */
    /*                                    error                                   */
    /* -------------------------------------------------------------------------- */
    error ErrInvalidToken();
    error ErrNotTokenOwner();
    error ErrStakingPeriodNotReached();
    error ErrClaimed();
    error ErrInvalidSignature();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event EvBatchStakeQuirkies(address indexed sender, Team[] teams);
    event EvBatchUnstakeQuirkies(address indexed sender, Team[] teams);
    event EvBatchClaim(address indexed sender, ClaimQuirkie[] claimQuirkies);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    address immutable QUIRKIES_ADDRESS;
    address immutable QUIRKLINGS_ADDRESS;
    address immutable ITEMS_ADDRESS;

    /* -------------------------------------------------------------------------- */
    /*                                 contructor                                 */
    /* -------------------------------------------------------------------------- */
    constructor(address quirkiesAddress_, address quirklingsAddress_, address itemsAddress_) {
        QUIRKIES_ADDRESS = quirkiesAddress_;
        QUIRKLINGS_ADDRESS = quirklingsAddress_;
        ITEMS_ADDRESS = itemsAddress_;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   public                                   */
    /* -------------------------------------------------------------------------- */
    function _stake(uint256 quirkieTokenID_, uint256 quirklingTokenID_, uint256 quirklingTokenID2_) internal {
        // stake quirkie
        {
            // check is owner
            if (IERC721(QUIRKIES_ADDRESS).ownerOf(quirkieTokenID_) != msg.sender) {
                revert ErrNotTokenOwner();
            }

            // stake
            ISoftStaking(QUIRKIES_ADDRESS).setStaked(quirkieTokenID_, true);
        }

        // stake quirklings
        {
            // check is owner
            if (IERC721(QUIRKLINGS_ADDRESS).ownerOf(quirklingTokenID_) != msg.sender) {
                revert ErrNotTokenOwner();
            }

            // stake
            ISoftStaking(QUIRKLINGS_ADDRESS).setStaked(quirklingTokenID_, true);
        }

        if (quirklingTokenID2_ != 0) {
            {
                // check is owner
                if (IERC721(QUIRKLINGS_ADDRESS).ownerOf(quirklingTokenID2_) != msg.sender) {
                    revert ErrNotTokenOwner();
                }

                // stake
                ISoftStaking(QUIRKLINGS_ADDRESS).setStaked(quirklingTokenID2_, true);
            }
        }
    }

    function batchStake(Team[] calldata teams) external {
        for (uint256 i = 0; i < teams.length;) {
            Team memory __team = teams[i];
            _stake(__team.quirkieTokenID, __team.quirklingTokenID, __team.quirklingTokenID2);
            unchecked {
                ++i;
            }
        }

        emit EvBatchStakeQuirkies(msg.sender, teams);
    }

    function _unstake(uint256 quirkieTokenID_, uint256 quirklingsTokenID_, uint256 quirklings2TokenID_) internal {
        // unstake quirkie
        {
            // check is owner
            if (IERC721(QUIRKIES_ADDRESS).ownerOf(quirkieTokenID_) != msg.sender) {
                revert ErrNotTokenOwner();
            }

            // unstake
            ISoftStaking(QUIRKIES_ADDRESS).setStaked(quirkieTokenID_, false);
        }

        // unstake quirklings
        {
            // check is owner
            if (IERC721(QUIRKLINGS_ADDRESS).ownerOf(quirklingsTokenID_) != msg.sender) {
                revert ErrNotTokenOwner();
            }

            // unstake
            ISoftStaking(QUIRKLINGS_ADDRESS).setStaked(quirklingsTokenID_, false);
        }

        if (quirklings2TokenID_ != 0) {
            {
                // check is owner
                if (IERC721(QUIRKLINGS_ADDRESS).ownerOf(quirklings2TokenID_) != msg.sender) {
                    revert ErrNotTokenOwner();
                }

                // unstake
                ISoftStaking(QUIRKLINGS_ADDRESS).setStaked(quirklings2TokenID_, false);
            }
        }
    }

    function batchUnstake(Team[] memory teams, bytes[] calldata signatures) external {
        // get nonce
        uint256 __n = QuestSeason2Storage.layout().nonceMap[msg.sender];

        // unstake
        for (uint256 i = 0; i < teams.length;) {
            Team memory __team = teams[i];

            // check
            bytes32 hash = keccak256(
                abi.encodePacked(
                    __team.quirkieTokenID, __team.quirklingTokenID, __team.quirklingTokenID2, msg.sender, __n
                )
            );
            if (hash.toEthSignedMessageHash().recover(signatures[i]) != QuestSeason2Storage.layout().signer) {
                revert ErrInvalidSignature();
            }

            // uncheck
            _unstake(__team.quirkieTokenID, __team.quirklingTokenID, __team.quirklingTokenID2);

            // loop
            unchecked {
                ++i;
            }
        }

        QuestSeason2Storage.layout().nonceMap[msg.sender] = __n + 1;
        emit EvBatchUnstakeQuirkies(msg.sender, teams);
    }

    function _claim(StakedTeam memory stakedTeam_, bool episode1, bool episode2, bool episode3, bool episode4)
        internal
    {
        uint256 __now = block.timestamp;

        // get claimed state
        ClaimedItems memory __quirkiesClaimed = QuestSeason2Storage.layout().quirkiesClaimedMap[stakedTeam_.tokenID];
        ClaimedItems memory __quirklingsClaimed =
            QuestSeason2Storage.layout().quirklingsClaimedMap[stakedTeam_.quirkling1];
        ClaimedItems memory __quirklings2Claimed =
            QuestSeason2Storage.layout().quirklingsClaimedMap[stakedTeam_.quirkling1];

        // episode 1
        if (episode1) {
            if (__now - stakedTeam_.timestamp < 30 days) {
                revert ErrStakingPeriodNotReached();
            }
            if (__quirkiesClaimed.episode1 || __quirklingsClaimed.episode1 || __quirklings2Claimed.episode1) {
                revert ErrClaimed();
            }

            __quirkiesClaimed.episode1 = true;
            QuestSeason2Storage.layout().quirkiesClaimedMap[stakedTeam_.tokenID] = __quirkiesClaimed;

            __quirklingsClaimed.episode1 = true;
            QuestSeason2Storage.layout().quirklingsClaimedMap[stakedTeam_.quirkling1] = __quirklingsClaimed;

            if (stakedTeam_.quirkling2 > 0) {
                __quirklings2Claimed.episode1 = true;
                QuestSeason2Storage.layout().quirklingsClaimedMap[stakedTeam_.quirkling2] = __quirklings2Claimed;
            }

            IItem(ITEMS_ADDRESS).claim(msg.sender, 0);
        }

        // episode 2
        if (episode2) {
            if (__now - stakedTeam_.timestamp < 60 days) {
                revert ErrStakingPeriodNotReached();
            }
            if (__quirkiesClaimed.episode2 || __quirklingsClaimed.episode2 || __quirklings2Claimed.episode2) {
                revert ErrClaimed();
            }

            __quirkiesClaimed.episode2 = true;
            QuestSeason2Storage.layout().quirkiesClaimedMap[stakedTeam_.tokenID] = __quirkiesClaimed;

            __quirklingsClaimed.episode2 = true;
            QuestSeason2Storage.layout().quirklingsClaimedMap[stakedTeam_.quirkling1] = __quirklingsClaimed;

            if (stakedTeam_.quirkling2 > 0) {
                __quirklings2Claimed.episode2 = true;
                QuestSeason2Storage.layout().quirklingsClaimedMap[stakedTeam_.quirkling2] = __quirklings2Claimed;
            }

            IItem(ITEMS_ADDRESS).claim(msg.sender, 1);
        }

        // episode 3
        if (episode3) {
            if (__now - stakedTeam_.timestamp < 90 days) {
                revert ErrStakingPeriodNotReached();
            }
            if (__quirkiesClaimed.episode3 || __quirklingsClaimed.episode3 || __quirklings2Claimed.episode3) {
                revert ErrClaimed();
            }

            __quirkiesClaimed.episode3 = true;
            QuestSeason2Storage.layout().quirkiesClaimedMap[stakedTeam_.tokenID] = __quirkiesClaimed;

            __quirklingsClaimed.episode3 = true;
            QuestSeason2Storage.layout().quirklingsClaimedMap[stakedTeam_.quirkling1] = __quirklingsClaimed;

            if (stakedTeam_.quirkling2 > 0) {
                __quirklings2Claimed.episode3 = true;
                QuestSeason2Storage.layout().quirklingsClaimedMap[stakedTeam_.quirkling2] = __quirklings2Claimed;
            }

            IItem(ITEMS_ADDRESS).claim(msg.sender, 2);
        }

        // episode 4
        if (episode4) {
            if (__now - stakedTeam_.timestamp < 120 days) {
                revert ErrStakingPeriodNotReached();
            }
            if (__quirkiesClaimed.episode4 || __quirklingsClaimed.episode4 || __quirklings2Claimed.episode4) {
                revert ErrClaimed();
            }

            __quirkiesClaimed.episode4 = true;
            QuestSeason2Storage.layout().quirkiesClaimedMap[stakedTeam_.tokenID] = __quirkiesClaimed;

            __quirklingsClaimed.episode4 = true;
            QuestSeason2Storage.layout().quirklingsClaimedMap[stakedTeam_.quirkling1] = __quirklingsClaimed;

            if (stakedTeam_.quirkling2 > 0) {
                __quirklings2Claimed.episode4 = true;
                QuestSeason2Storage.layout().quirklingsClaimedMap[stakedTeam_.quirkling2] = __quirklings2Claimed;
            }

            IItem(ITEMS_ADDRESS).claim(msg.sender, 3);
        }
    }

    function batchClaim(ClaimQuirkie[] memory claimQuirkies_, bytes[] calldata signatures) external {
        // get nonce
        uint256 __n = QuestSeason2Storage.layout().nonceMap[msg.sender];

        for (uint256 i = 0; i < claimQuirkies_.length;) {
            ClaimQuirkie memory __claimQuirkie = claimQuirkies_[i];

            // check
            bytes32 hash = keccak256(
                abi.encodePacked(
                    __claimQuirkie.team.tokenID,
                    __claimQuirkie.team.quirkling1,
                    __claimQuirkie.team.quirkling2,
                    __claimQuirkie.team.timestamp,
                    msg.sender,
                    __n
                )
            );
            if (hash.toEthSignedMessageHash().recover(signatures[i]) != QuestSeason2Storage.layout().signer) {
                revert ErrInvalidSignature();
            }

            // claim
            _claim(
                __claimQuirkie.team,
                __claimQuirkie.episode1,
                __claimQuirkie.episode2,
                __claimQuirkie.episode3,
                __claimQuirkie.episode4
            );

            // loop
            unchecked {
                ++i;
            }
        }

        QuestSeason2Storage.layout().nonceMap[msg.sender] = __n + 1;
        emit EvBatchClaim(msg.sender, claimQuirkies_);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function setSigner(address signer_) external onlyOwner {
        QuestSeason2Storage.layout().signer = signer_;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function stakersMap(address addr) external view returns (Staker memory) {
        return QuestSeason2Storage.layout().stakersMap[addr];
    }

    function quirkiesClaimedMap(uint256 tokenID_) external view returns (ClaimedItems memory) {
        return QuestSeason2Storage.layout().quirkiesClaimedMap[tokenID_];
    }

    function quirklingsClaimedMap(uint256 tokenID_) external view returns (ClaimedItems memory) {
        return QuestSeason2Storage.layout().quirklingsClaimedMap[tokenID_];
    }

    function nonceMap(address addr) external view returns (uint256) {
        return QuestSeason2Storage.layout().nonceMap[addr];
    }
}