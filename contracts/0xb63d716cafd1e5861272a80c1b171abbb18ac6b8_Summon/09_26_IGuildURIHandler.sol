// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGuildURIHandler {
    /**
     * @notice Branches represent various guild buffs
     * each of which are capped at level 5
     *
     * FRUGALITY: Rebate on CFTI sinks
     * 0.5% | 1% | 1.5% | 2% | 2.5%
     *
     * DISCIPLINE: Flat damage buff
     * 2 * heroBaseDmg * (heroLevel + 1) * perkLevel
     *
     * MORALE: Damage multiplier
     * 1.5% | 3% | 5% | 7% | 10%
     *
     * INDEMNITY: Second-wind chance on failure
     * 1% | 2% | 3% | 4% | 10%
     *
     * SUPERSTITION: Downgrade chance decrease
     * 1% | 2% | 3% | 4% | 5%
     *
     * FORTUNE: Enhancement success chance increase
     * 1% | 2% | 3% | 4% | 5%
     *
     */
    // NOTE: Keep in sync with `struct TechTree`
    enum Branch {
        FRUGALITY,
        DISCIPLINE,
        MORALE,
        INDEMNITY,
        SUPERSTITION,
        FORTUNE
    }

    /** STRUCTS */

    /**
     * @notice Below is documentation on Member struct elements.
     *
     * @param guildId       current active guild ID
     * @param vault         current vault balance
     * @param lastForage    last forage timestamp
     * @param hero          current staked hero
     * @param slot          current slot in guild membership array
     * @param permissions   permissions bitmap for current guild
     *
     */
    struct Member {
        uint256 guildId;
        uint64 vault;
        uint64 lastForage;
        uint32 hero;
        uint16 slot;
        uint8 permissions;
    }

    /**
     * @notice Below is documentation on Guild struct elements.
     *
     * @param balance  current guild GCFTI balance
     * @param vault    cumulative vault holdings of guild members
     * @param level    current guild level
     * @param techTree compact set of tech tree levels for each branch
     * @param members  array of guild members
     *
     */
    struct Guild {
        uint64 balance;
        uint64 vault;
        uint16 level;
        uint256 techTree;
        bytes32 name;
        address[] members;
    }

    struct Invite {
        address user;
        uint256 guildId;
        uint256 timeout;
    }

    // NOTE: Keep in sync with `enum Branch`
    struct TechTree {
        uint16 frugality;
        uint16 discipline;
        uint16 morale;
        uint16 indemnity;
        uint16 superstition;
        uint16 fortune;
        uint160 _scratch;
    }

    /** FUNCTIONS */

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getMembers(uint256 guildId)
        external
        view
        returns (address[] memory);

    function getGuildLevel(uint256 guildId) external view returns (uint16);

    function getGuildTechLevel(uint256 guildId, Branch branch)
        external
        view
        returns (uint16);

    function getGuildVault(uint256 guildId) external view returns (uint64);

    function getGuildBalance(uint256 guildId) external view returns (uint64);

    function getGuildData(uint256 guildId)
        external
        view
        returns (
            uint64 balance,
            uint16 level,
            uint64 vault,
            TechTree memory techTree,
            address[] memory members,
            string memory name
        );

    function getMember(address user) external view returns (Member memory);

    function getGuild(address user) external view returns (uint256);

    function calculateRewards(uint256 rewards, uint256 guildId)
        external
        view
        returns (uint64);

    function getGuildTechTree(uint256 guildId)
        external
        view
        returns (TechTree memory);

    function mint(address user, uint64 amount) external;
}