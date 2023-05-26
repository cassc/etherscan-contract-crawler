// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title The Humanians Staking
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://thehumanians.com

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract HumanianStaking is Ownable {
    IERC721Enumerable public immutable humanians;
    bool public stakingActive = false;

    struct StakedInfo {
        address owner;
        uint64 stakedAt;
    }

    mapping(uint256 => StakedInfo) public tokenStakedInfo;

    constructor(address humanians_) {
        humanians = IERC721Enumerable(humanians_);
    }

    /**
     * Stake.
     * @param tokenIds The tokens to be staked.
     */
    function stake(uint256[] memory tokenIds) external {
        require(stakingActive, "HumanianStaking: Staking not active");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            humanians.transferFrom(msg.sender, address(this), tokenId);
            tokenStakedInfo[tokenId] = StakedInfo(msg.sender, uint64(block.timestamp));
        }
    }

    /**
     * Unstake.
     * @param tokenIds The tokens to be unstaked.
     */
    function unstake(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakedInfo memory info = tokenStakedInfo[tokenId];
            require(info.owner == msg.sender, "HumanianStaking: Only owner can unstake");
            delete tokenStakedInfo[tokenId];
            // Send it back
            humanians.transferFrom(address(this), msg.sender, tokenId);
        }
    }

    //
    // Admin
    //

    /**
     * Enable/disable staking.
     * @param stakingActive_ The new staking state.
     */
    function setStakingActive(bool stakingActive_) external onlyOwner {
        stakingActive = stakingActive_;
    }

    /**
     * Recover a staked token in an emergency situation.
     * @param tokenId The token to unstake.
     * @param to The address to send the token to.
     * @notice This method will only be called in emergency situations.
     */
    function emergencyUnstake(uint256 tokenId, address to) external onlyOwner {
        delete tokenStakedInfo[tokenId];
        humanians.transferFrom(address(this), to, tokenId);
    }

    //
    // Views
    //

    /**
     * Get owner of staked token.
     * @param tokenId The token Id address to query.
     */
    function getTokenOwner(uint256 tokenId) public view returns (address) {
        return tokenStakedInfo[tokenId].owner;
    }

    /**
     * Get timestamp of when the token was staked.
     * @param tokenId The token Id address to query.
     */
    function getStakedAt(uint256 tokenId) public view returns (uint64) {
        return tokenStakedInfo[tokenId].stakedAt;
    }

    /**
     * List all the staked tokens owned by the given address.
     * @param owner The owner address to query.
     */
    function listStakedTokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 supply = humanians.totalSupply();
        uint256[] memory tokenIds = new uint256[](supply);
        uint256 count = 0;
        for (uint256 tokenId = 0; tokenId < supply; tokenId++) {
            if (getTokenOwner(tokenId) == owner) {
                tokenIds[count] = tokenId;
                count++;
            }
        }
        return resizeArray(tokenIds, count);
    }

    /**
     * List all the staked token start times owned by the given address.
     * @param owner The owner address to query.
     */
    function listStakedAtTimesOfOwner(address owner) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = listStakedTokensOfOwner(owner);
        uint256[] memory stakedAts = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakedAts[i] = getStakedAt(tokenIds[i]);
        }
        return stakedAts;
    }

    /**
     * Helper function to resize an array.
     */
    function resizeArray(uint256[] memory input, uint256 length) internal pure returns (uint256[] memory) {
        uint256[] memory output = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = input[i];
        }
        return output;
    }
}