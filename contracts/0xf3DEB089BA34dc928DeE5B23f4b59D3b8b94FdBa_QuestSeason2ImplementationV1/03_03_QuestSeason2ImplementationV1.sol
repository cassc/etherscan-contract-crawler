// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC721/IERC721.sol";

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
    uint256 quirkieTokenID;
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
contract QuestSeason2ImplementationV1 {
    /* -------------------------------------------------------------------------- */
    /*                                    error                                   */
    /* -------------------------------------------------------------------------- */
    error ErrInvalidToken();
    error ErrNotTokenOwner();
    error ErrStakingPeriodNotReached();
    error ErrClaimed();

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

    /* -------------------------------------------------------------------------- */
    /*                                   public                                   */
    /* -------------------------------------------------------------------------- */
    function _stake(uint256 quirkieTokenID_, uint256 quirklingTokenID_, uint256 quirklingTokenID2_) internal {
        uint256 __now = block.timestamp;

        // update state
        Staker storage $staker = QuestSeason2Storage.layout().stakersMap[msg.sender];
        $staker.stakedTeams.push(
            StakedTeam({
                tokenID: quirkieTokenID_,
                quirkling1: quirklingTokenID_,
                quirkling2: quirklingTokenID2_,
                timestamp: __now
            })
        );
        QuestSeason2Storage.layout().quirkiesStakedMap[quirkieTokenID_] =
            StakedQuirkies({owner: msg.sender, timestamp: __now});
        QuestSeason2Storage.layout().quirklingsStakedMap[quirklingTokenID_] =
            StakedQuirklings({owner: msg.sender, timestamp: __now});
        if (quirklingTokenID2_ != 0) {
            QuestSeason2Storage.layout().quirklingsStakedMap[quirklingTokenID2_] =
                StakedQuirklings({owner: msg.sender, timestamp: __now});
        }

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

    function _unstake(StakedTeam[] memory stakedTeams_, uint256 quirkieTokenID_)
        internal
        returns (uint256 quirklingsID1_, uint256 quirkingsID2_)
    {
        // get staker
        StakedTeam[] memory __stakedTeams = stakedTeams_;

        // check valid
        bool __isValid = false;
        uint256 __index = 0;
        uint256 __quirklingID1;
        uint256 __quirklingID2;
        for (uint256 i = 0; i < __stakedTeams.length; i++) {
            StakedTeam memory __stakedQuirkie = __stakedTeams[i];
            if (__stakedQuirkie.tokenID == quirkieTokenID_) {
                __quirklingID1 = __stakedQuirkie.quirkling1;
                __quirklingID2 = __stakedQuirkie.quirkling2;
                __isValid = true;
                __index = i;
                break;
            }
        }

        if (!__isValid) {
            revert ErrInvalidToken();
        }

        // update state
        QuestSeason2Storage.layout().stakersMap[msg.sender].stakedTeams[__index] =
            __stakedTeams[__stakedTeams.length - 1];
        QuestSeason2Storage.layout().stakersMap[msg.sender].stakedTeams.pop();
        delete QuestSeason2Storage.layout().quirkiesStakedMap[quirkieTokenID_];
        delete QuestSeason2Storage.layout().quirklingsStakedMap[__quirklingID1];
        delete QuestSeason2Storage.layout().quirklingsStakedMap[__quirklingID2];

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
            if (IERC721(QUIRKLINGS_ADDRESS).ownerOf(__quirklingID1) != msg.sender) {
                revert ErrNotTokenOwner();
            }

            // unstake
            ISoftStaking(QUIRKLINGS_ADDRESS).setStaked(__quirklingID1, false);
        }

        if (__quirklingID2 != 0) {
            {
                // check is owner
                if (IERC721(QUIRKLINGS_ADDRESS).ownerOf(__quirklingID2) != msg.sender) {
                    revert ErrNotTokenOwner();
                }

                // unstake
                ISoftStaking(QUIRKLINGS_ADDRESS).setStaked(__quirklingID2, false);
            }
        }

        quirklingsID1_ = __quirklingID1;
        quirkingsID2_ = __quirklingID2;
    }

    function batchUnstake(uint256[] memory quirkieTokenIDs_) external {
        // get staker
        Staker storage $staker = QuestSeason2Storage.layout().stakersMap[msg.sender];
        StakedTeam[] memory __stakedTeams = $staker.stakedTeams;

        // unstake
        Team[] memory teams = new Team[](quirkieTokenIDs_.length);
        for (uint256 i = 0; i < quirkieTokenIDs_.length;) {
            uint256 __quirkiesTokenID = quirkieTokenIDs_[i];
            (uint256 __quirklingsID1, uint256 __quirklingsID2) = _unstake(__stakedTeams, __quirkiesTokenID);
            teams[i] = Team({
                quirkieTokenID: __quirkiesTokenID,
                quirklingTokenID: __quirklingsID1,
                quirklingTokenID2: __quirklingsID2
            });
            unchecked {
                ++i;
            }
        }

        emit EvBatchUnstakeQuirkies(msg.sender, teams);
    }

    function _claim(
        StakedTeam[] memory stakedTeams_,
        uint256 quirkieTokenID_,
        bool episode1,
        bool episode2,
        bool episode3,
        bool episode4
    ) internal {
        StakedTeam[] memory __stakedTeams = stakedTeams_;

        // check valid
        bool __isValid = false;
        uint256 __index = 0;
        for (uint256 i = 0; i < __stakedTeams.length; i++) {
            StakedTeam memory __stakedTeam = __stakedTeams[i];
            if (__stakedTeam.tokenID == quirkieTokenID_) {
                __isValid = true;
                __index = i;
                break;
            }
        }

        if (!__isValid) {
            revert ErrInvalidToken();
        }

        uint256 __now = block.timestamp;
        StakedTeam memory __stakedTeam = __stakedTeams[__index];

        // get claimed state
        ClaimedItems memory __quirkiesClaimed = QuestSeason2Storage.layout().quirkiesClaimedMap[__stakedTeam.tokenID];
        ClaimedItems memory __quirklingsClaimed =
            QuestSeason2Storage.layout().quirklingsClaimedMap[__stakedTeam.quirkling1];
        ClaimedItems memory __quirklings2Claimed =
            QuestSeason2Storage.layout().quirklingsClaimedMap[__stakedTeam.quirkling1];

        // episode 1
        if (episode1) {
            if (__now - __stakedTeam.timestamp < 30 days) {
                revert ErrStakingPeriodNotReached();
            }
            if (__quirkiesClaimed.episode1 || __quirklingsClaimed.episode1 || __quirklings2Claimed.episode1) {
                revert ErrClaimed();
            }

            __quirkiesClaimed.episode1 = true;
            QuestSeason2Storage.layout().quirkiesClaimedMap[__stakedTeam.tokenID] = __quirkiesClaimed;

            __quirklingsClaimed.episode1 = true;
            QuestSeason2Storage.layout().quirklingsClaimedMap[__stakedTeam.quirkling1] = __quirklingsClaimed;

            if (__stakedTeam.quirkling2 > 0) {
                __quirklings2Claimed.episode1 = true;
                QuestSeason2Storage.layout().quirklingsClaimedMap[__stakedTeam.quirkling2] = __quirklings2Claimed;
            }

            IItem(ITEMS_ADDRESS).claim(msg.sender, 0);
        }

        // episode 2
        if (episode2) {
            if (__now - __stakedTeam.timestamp < 60 days) {
                revert ErrStakingPeriodNotReached();
            }
            if (__quirkiesClaimed.episode2 || __quirklingsClaimed.episode2 || __quirklings2Claimed.episode2) {
                revert ErrClaimed();
            }

            __quirkiesClaimed.episode2 = true;
            QuestSeason2Storage.layout().quirkiesClaimedMap[__stakedTeam.tokenID] = __quirkiesClaimed;

            __quirklingsClaimed.episode2 = true;
            QuestSeason2Storage.layout().quirklingsClaimedMap[__stakedTeam.quirkling1] = __quirklingsClaimed;

            if (__stakedTeam.quirkling2 > 0) {
                __quirklings2Claimed.episode2 = true;
                QuestSeason2Storage.layout().quirklingsClaimedMap[__stakedTeam.quirkling2] = __quirklings2Claimed;
            }

            IItem(ITEMS_ADDRESS).claim(msg.sender, 1);
        }

        // episode 3
        if (episode3) {
            if (__now - __stakedTeam.timestamp < 90 days) {
                revert ErrStakingPeriodNotReached();
            }
            if (__quirkiesClaimed.episode3 || __quirklingsClaimed.episode3 || __quirklings2Claimed.episode3) {
                revert ErrClaimed();
            }

            __quirkiesClaimed.episode3 = true;
            QuestSeason2Storage.layout().quirkiesClaimedMap[__stakedTeam.tokenID] = __quirkiesClaimed;

            __quirklingsClaimed.episode3 = true;
            QuestSeason2Storage.layout().quirklingsClaimedMap[__stakedTeam.quirkling1] = __quirklingsClaimed;

            if (__stakedTeam.quirkling2 > 0) {
                __quirklings2Claimed.episode3 = true;
                QuestSeason2Storage.layout().quirklingsClaimedMap[__stakedTeam.quirkling2] = __quirklings2Claimed;
            }

            IItem(ITEMS_ADDRESS).claim(msg.sender, 2);
        }

        // episode 4
        if (episode4) {
            if (__now - __stakedTeam.timestamp < 120 days) {
                revert ErrStakingPeriodNotReached();
            }
            if (__quirkiesClaimed.episode4 || __quirklingsClaimed.episode4 || __quirklings2Claimed.episode4) {
                revert ErrClaimed();
            }

            __quirkiesClaimed.episode4 = true;
            QuestSeason2Storage.layout().quirkiesClaimedMap[__stakedTeam.tokenID] = __quirkiesClaimed;

            __quirklingsClaimed.episode4 = true;
            QuestSeason2Storage.layout().quirklingsClaimedMap[__stakedTeam.quirkling1] = __quirklingsClaimed;

            if (__stakedTeam.quirkling2 > 0) {
                __quirklings2Claimed.episode4 = true;
                QuestSeason2Storage.layout().quirklingsClaimedMap[__stakedTeam.quirkling2] = __quirklings2Claimed;
            }

            IItem(ITEMS_ADDRESS).claim(msg.sender, 3);
        }
    }

    function batchClaim(ClaimQuirkie[] memory claimQuirkies_) external {
        // get staker
        Staker storage $staker = QuestSeason2Storage.layout().stakersMap[msg.sender];
        StakedTeam[] memory __stakedTeams = $staker.stakedTeams;

        for (uint256 i = 0; i < claimQuirkies_.length;) {
            ClaimQuirkie memory __claimQuirkie = claimQuirkies_[i];

            _claim(
                __stakedTeams,
                __claimQuirkie.quirkieTokenID,
                __claimQuirkie.episode1,
                __claimQuirkie.episode2,
                __claimQuirkie.episode3,
                __claimQuirkie.episode4
            );
        }

        emit EvBatchClaim(msg.sender, claimQuirkies_);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function stakersMap(address addr) external view returns (Staker memory) {
        return QuestSeason2Storage.layout().stakersMap[addr];
    }

    function quirkiesStakedMap(uint256 quirkiesTokenID_) external view returns (StakedQuirkies memory) {
        return QuestSeason2Storage.layout().quirkiesStakedMap[quirkiesTokenID_];
    }

    function quirklingsStakedMap(uint256 quirklingsTokenID_) external view returns (StakedQuirklings memory) {
        return QuestSeason2Storage.layout().quirklingsStakedMap[quirklingsTokenID_];
    }

    function quirkiesClaimedMap(uint256 tokenID_) external view returns (ClaimedItems memory) {
        return QuestSeason2Storage.layout().quirkiesClaimedMap[tokenID_];
    }

    function quirklingsClaimedMap(uint256 tokenID_) external view returns (ClaimedItems memory) {
        return QuestSeason2Storage.layout().quirklingsClaimedMap[tokenID_];
    }
}