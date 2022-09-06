// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "solmate/src/auth/Owned.sol";
import "solmate/src/tokens/ERC20.sol";
import "solmate/src/tokens/ERC721.sol";
import "solmate/src/utils/ReentrancyGuard.sol";

import {Free2Own} from "./Free2Own.sol";
import {SBC} from "./SBC.sol";

contract STAKEABLE is Owned, ReentrancyGuard {
    event COLLECTED(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount
    );

    struct Stake {
        uint256 tokenId;
        uint256 timestamp;
    }

    uint256 public constant DAILY_OWNER_REWARD = 1000 ether;

    address public f2o;
    address public sbc;
    mapping(uint256 => Stake) public stakes;

    constructor(address _f2o, address _sbc) Owned(msg.sender) {
        f2o = _f2o;
        sbc = _sbc;
    }

    /// WHEN YOU ARE OWNABLE AND STAKEABLE, GOOD THINGS HAPPEN ///

    function getCurrentSBC(uint256 tokenId)
        public
        view
        returns (uint256 earned)
    {
        Stake memory stake = stakes[tokenId];
        require(stake.tokenId == tokenId, "not very STAKEABLE of you");

        if (stake.timestamp == 0) {
            earned = 0;
        } else {
            earned =
                ((block.timestamp - stake.timestamp) * DAILY_OWNER_REWARD) /
                1 days;
        }

        return earned;
    }

    function stakeF2O(uint256 tokenId) external {
        require(msg.sender == f2o, "only OWNERS can STAKEABLE");

        stakes[tokenId] = Stake({tokenId: tokenId, timestamp: block.timestamp});
    }

    function collectSBC(uint256[] calldata tokenIds) external nonReentrant {
        uint256 reward;
        for (uint256 idx; idx < tokenIds.length; ++idx) {
            reward += _collectSBC(msg.sender, tokenIds[idx]);
        }

        if (reward > 0) {
            SBC(sbc).mint(msg.sender, reward);
        }
    }

    /// ONLY OWNERS LOOK BEYOND THIS POINT ///

    function _collectSBC(address account, uint256 tokenId)
        internal
        returns (uint256 earned)
    {
        // Validate ownership.
        require(
            Free2Own(f2o).ownerOf(tokenId) == account,
            "have you not listened about OWNING"
        );

        earned = getCurrentSBC(tokenId);

        Stake storage stake = stakes[tokenId];
        stake.timestamp = block.timestamp;

        if (earned > 0) {
            emit COLLECTED(account, tokenId, earned);
        }

        return earned;
    }
}