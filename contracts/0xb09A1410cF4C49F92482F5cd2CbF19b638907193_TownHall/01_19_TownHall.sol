// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Building.sol";

contract TownHall {
    error TownHall__LockUpPeroidStillLeft();
    error TownHall__InvalidTokenId();

    using SafeERC20 for IERC20;

    Building public building;
    IERC20 public huntToken;

    uint256 public constant LOCK_UP_AMOUNT = 1e21; // 1,000 HUNT per NFT minting
    uint256 public constant LOCK_UP_DURATION = 31536000; // 365 days in seconds

    mapping (uint256 => uint256) private buildingMintedAt;

    event Mint(address indexed to, uint256 indexed tokenId, uint256 timestamp);
    event Burn(address indexed caller, uint256 indexed tokenId, uint256 timestamp);

    constructor(address building_, address huntToken_) {
        building = Building(building_);
        huntToken = IERC20(huntToken_);
    }

    /**
     * @dev Mint a new building NFT with a lock-up of HUNT tokens for 1 year
     */
    function mint(address to) external {
        huntToken.safeTransferFrom(msg.sender, address(this), LOCK_UP_AMOUNT);
        uint256 tokenId = building.safeMint(to);

        buildingMintedAt[tokenId] = block.timestamp;

        emit Mint(to, tokenId, block.timestamp);
    }

    /**
     * @dev Burn a existing building NFT and refund locked-up HUNT Tokens
     */
    function burn(uint256 tokenId) external {
        if (block.timestamp < unlockTime(tokenId)) revert TownHall__LockUpPeroidStillLeft();

        // Check approvals and burn the building NFT
        building.burn(tokenId, msg.sender);

        // Refund locked-up HUNT tokens
        huntToken.safeTransfer(msg.sender, LOCK_UP_AMOUNT);

        emit Burn(msg.sender, tokenId, block.timestamp);
    }

    function mintedAt(uint256 tokenId) external view returns (uint256) {
        if(!building.exists(tokenId)) revert TownHall__InvalidTokenId();

        return buildingMintedAt[tokenId];
    }

    function unlockTime(uint256 tokenId) public view returns (uint256) {
        if(!building.exists(tokenId)) revert TownHall__InvalidTokenId();

        return buildingMintedAt[tokenId] + LOCK_UP_DURATION;
    }
}