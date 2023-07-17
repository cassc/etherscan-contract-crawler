// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface iczNft is IERC721Enumerable {

    // store lock meta data
    struct Locked {
        uint256 tokenId;
        uint8 lockType; // staking = 1; bridging = 2
        uint256 lockTimestamp;
    }

    function MAX_TOKENS() external returns (uint256);
    function totalMinted() external returns (uint16);
    function totalLocked() external returns (uint16);
    function totalStaked() external returns (uint16);
    function totalBridged() external returns (uint16);

    function mint(address recipient) external; // onlyAdmin
    function burn(uint256 tokenId) external; // onlyAdmin

    function lock(uint256 tokenId, uint8 lockType) external; // onlyAdmin
    function unlock(uint256 tokenId) external; // onlyAdmin
    function refreshLock(uint256 tokenId) external; // onlyAdmin
    function getLock(uint256 tokenId) external view returns (Locked memory);

    function isLocked(uint256 tokenId) external view returns(bool);
    function isStaked(uint256 tokenId) external view returns(bool);
    function isBridged(uint256 tokenId) external view returns(bool);

    function getAllStakedOrLockedTokens(address owner, uint8 lockType) external returns (uint256[] memory);
    function getWalletOfOwner(address owner) external view returns (uint256[] memory);
    function addToSpecialTraits(uint256 tokenId, uint16 traitId) external;
    function getSpecialTraits(uint256 tokenId) external view returns (uint16[] memory);
}