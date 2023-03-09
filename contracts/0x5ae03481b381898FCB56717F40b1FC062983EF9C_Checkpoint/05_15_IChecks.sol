// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Checks contract
interface IChecks {
    struct StoredCheck {
        uint32 seed; // The seed is based the mint and enables pseudo-randomisation
        uint16[6] composites; // The tokenIds that were composited into this one
        uint8[6] colorBands; // The length of the used color band in percent
        uint8[6] gradients; // Gradient settings for each generation
        uint8 divisorIndex; // Easy access to next / previous divisor
        uint8 animation; // Animation seed
    }

    struct Check {
        StoredCheck stored;
        uint16 composite; // The parent tokenId that was composited into this one
        bool hasManyChecks; // Quick access for whether the check has many checks
        uint8 checksCount; // How many checks this token has
        uint8 colorBand; // 100%, 50%, 25%, 12.5%, 6.25%, 5%, 1.25%
        uint8 gradient; // Linearly through the colorBand [1, 2, 3]
        uint8 direction; // Animation direction
        uint8 speed; // Animation speed
    }

    struct Checks {
        uint32 minted;
        uint32 burned;
        mapping(uint256 => StoredCheck) all;
    }

    event Sacrifice(uint256 indexed burnedId, uint256 indexed tokenId);

    event Composite(uint256 indexed tokenId, uint256 indexed burnedId, uint8 indexed checks);

    event Infinity(uint256 indexed tokenId, uint256[] indexed burnedIds);

    function compositeMany(uint256[] calldata _tokenIds, uint256[] calldata _burnIds) external;

    function getCheck(uint256 _tokenId) external view returns (Check memory);

    function infinity(uint256[] calldata _tokenIds) external;

    function mint(uint256[] calldata _tokenIds) external;
}