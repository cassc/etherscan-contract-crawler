// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IMonuverseEpisode {
    struct MintGroupRules {
        bool enabled;
        bool fixedPrice;
    }

    struct Minting {
        uint256 limit;
        uint256 price;
        mapping(bytes32 => MintGroupRules) rules;
        bool isOpen;
    }

    struct Chapter {
        Minting minting;
        bool whitelisting;
        bool revealing;
        bool exists;
    }

    /// @notice Episode writing events
    event ChapterWritten(
        string label,
        bool whitelisting,
        uint256 mintAllocation,
        uint256 mintPrice,
        bool mintOpen,
        bool revealing,
        bool isConclusion
    );
    event ChapterRemoved(string label);
    event TransitionWritten(string from, string to, string monumentalEvent);
    event TransitionRemoved(string from, string monumentalEvent);
    event MintGroupWritten(string chapter, string group, bool fixedPrice);
    event MintGroupRemoved(string chapter, string group);

    /// @notice Special Monumental Events
    event ChapterMinted(bytes32 prev, bytes32 current);
    event MintingSealed(bytes32 prev, bytes32 current);
    event EpisodeMinted(bytes32 prev, bytes32 current);
    event EpisodeRevealed(bytes32 prev, bytes32 current);
    event EpisodeProgressedOnlife(bytes32 prev, bytes32 current);

    function writeChapter(
        string calldata label,
        bool whitelisting,
        uint256 mintAllocation,
        uint256 mintPrice,
        bool mintOpen,
        bool revealing,
        bool isConlusion
    ) external returns (bytes32);

    function removeChapter(string calldata label) external;

    function writeMintGroup(
        string calldata chapter,
        string calldata group,
        MintGroupRules calldata mintingRules
    ) external;

    function removeMintGroup(string calldata chapter, string calldata group) external;

    function writeTransition(
        string calldata from,
        string calldata to,
        string calldata storyEvent
    ) external;

    function removeTransition(string calldata from, string calldata storyEvent) external;
}