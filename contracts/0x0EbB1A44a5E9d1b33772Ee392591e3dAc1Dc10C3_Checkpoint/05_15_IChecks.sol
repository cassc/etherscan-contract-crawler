// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IChecks {
    struct StoredCheck {
        uint16[6] composites; // The tokenIds that were composited into this one
        uint8[5] colorBands; // The length of the used color band in percent
        uint8[5] gradients; // Gradient settings for each generation
        uint8 divisorIndex; // Easy access to next / previous divisor
        uint32 epoch; // Each check is revealed in an epoch
        uint16 seed; // A unique identifyer to enable swapping
        uint24 day; // The days since token was created
    }

    struct Check {
        StoredCheck stored; // We carry over the check from storage
        bool isRevealed; // Whether the check is revealed
        uint256 seed; // The instantiated seed for pseudo-randomisation
        uint8 checksCount; // How many checks this token has
        bool hasManyChecks; // Whether the check has many checks
        uint16 composite; // The parent tokenId that was composited into this one
        bool isRoot; // Whether it has no parents (80 checks)
        uint8 colorBand; // 100%, 50%, 25%, 12.5%, 6.25%, 5%, 1.25%
        uint8 gradient; // Linearly through the colorBand [1, 2, 3]
        uint8 direction; // Animation direction
        uint8 speed; // Animation speed
    }

    struct Epoch {
        uint128 randomness; // The source of randomness for tokens from this epoch
        uint64 revealBlock; // The block at which this epoch was / is revealed
        bool committed; // Whether the epoch has been instantiated
        bool revealed; // Whether the epoch has been revealed
    }

    struct Checks {
        mapping(uint256 => StoredCheck) all; // All checks
        uint32 minted; // The number of checks editions that have been migrated
        uint32 burned; // The number of tokens that have been burned
        uint32 day0; // Marks the start of this journey
        mapping(uint256 => Epoch) epochs; // All epochs
        uint256 epoch; // The current epoch index
    }

    error NotAllowed();
    error InvalidTokenCount();
    error BlackCheck__InvalidCheck();

    event Sacrifice(uint256 indexed burnedId, uint256 indexed tokenId);
    event Composite(uint256 indexed tokenId, uint256 indexed burnedId, uint8 indexed checks);
    event Infinity(uint256 indexed tokenId, uint256[] indexed burnedIds);
    event NewEpoch(uint256 indexed epoch, uint64 indexed revealBlock);

    function compositeMany(uint256[] calldata tokenIds, uint256[] calldata burnIds) external;

    function infinity(uint256[] calldata tokenIds) external;

    function getCheck(uint256 tokenId) external view returns (Check memory);

    function mint(uint256[] calldata tokenIds, address recipient) external;
}