// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721Whitelist is Ownable {

    mapping(address => uint256) public whitelistSpotsOf;
    uint256 public immutable maxWhitelistSpots;
    uint256 public whitelistSpotsOpen;
    uint256 public whitelistSpotsTotal;


    constructor(uint256 _maxWhitelistSpots) {
        maxWhitelistSpots = _maxWhitelistSpots;
    }

    /**
     * @notice Grant `amount` whitelist mints to be used by `to`. Only callable by owner.
     */
    function grantWhitelistSpots(address to, uint256 amount) external onlyOwner {
        require(whitelistSpotsOpen + amount <= maxWhitelistSpots, "Exceeds maxWhitelistSpots");
        whitelistSpotsOf[to] += amount;
        whitelistSpotsOpen += amount;
        whitelistSpotsTotal += amount;
    }

    /**
     * @notice Grant `amounts` whitelist mints to be used by the respective entry of `to`. Only callable by owner.
     */
    function grantWhitelistSpotsBatch(address[] calldata to, uint256[] memory amounts) external onlyOwner {
        require(to.length == amounts.length, "Length missmatch");
        uint256 total = 0;

        for (uint256 i = 0; i < to.length; ++i) {
            whitelistSpotsOf[to[i]] += amounts[i];
            total += amounts[i];
        }

        whitelistSpotsOpen += total;
        whitelistSpotsTotal += total;
        require(whitelistSpotsTotal <= maxWhitelistSpots, "Exceeds maxWhitelistSpots");
    }

    /**
     * @notice Consume `amount` whitelist spots of `user`, fails if user has insufficient WL spots.
     */
    function consumeWhitelistSpots(address user, uint256 amount) internal {
        require(whitelistSpotsOf[user] >= amount, "Exceeds whitelist spots");
        whitelistSpotsOf[user] -= amount;
        whitelistSpotsOpen -= amount;
    }
}