// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

// @todo we will need documentation here
// for examples see OpenZeppelin contracts

interface IBooster {
    enum Status {
        Boosted,
        Ready,
        Locked,
        NotReady
    }

    event Boosted(uint256 indexed tokenId, uint256 boostAmount, uint256 level, bool value);

    function getStatus(uint256 tokenId) external view returns (Status);

    function getName() external view returns (string memory);

    function getBoost() external view returns (uint256);

    function getRequirements() external view returns (string memory description, uint256[] memory values);

    function isReady(uint256 tokenID) external view returns (bool);

    function boost(uint256[] calldata tokenIds) external;

    function unBoost(uint256[] calldata tokens) external;

    function numInCollection() external view returns (uint256);

    function isLocked(uint256 tokenId) external view returns (bool);

    function isBoosted(uint256 tokenId) external view returns (bool);

    function getBoostAmount(uint256 tokenId, uint256 amount) external view returns (uint256);
}