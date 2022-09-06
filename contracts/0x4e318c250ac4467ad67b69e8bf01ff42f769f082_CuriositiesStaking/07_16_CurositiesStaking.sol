// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721AQueryable} from "./IERC721AQueryable.sol";
import {ICuriousNative} from "./ICuriousNative.sol";

/// @author tempest-sol<tempest-sol.eth>
contract CuriositiesStaking is OwnableUpgradeable, PausableUpgradeable {

    /// 15 May 2022 : 00:00:00
    uint48 public constant START_TIMESTAMP = 1652590800;
    uint256 public constant TOKENS_PER_DAY = 10 ether;
    uint256 public constant FRAGMENTS_PER_DAY = 3 ether;

    IERC721 public curiosities;
    ICuriousNative public nativeToken;

    struct StakingRecord {
        uint48 lastClaimTimestamp;
    }

    mapping(uint16 => StakingRecord) private tokenRecords;
    mapping(address => uint256) private fragmentStorage;

    event RewardsClaimed(address indexed addr, uint256 indexed tokenId, uint256 native, uint256 fragments);

    function initialize(address _curiosities, address _nativeToken) public initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        curiosities = IERC721(_curiosities);
        nativeToken = ICuriousNative(_nativeToken);
    }

    function elapsedTimeFor(uint256 tokenId) internal view returns (uint48) {
        uint48 lastClaim = tokenRecords[uint16(tokenId)].lastClaimTimestamp;
        return uint48(block.timestamp) - (lastClaim == 0 ? START_TIMESTAMP : lastClaim);
    }

    function calculateRewardsFor(uint256 tokenId) public view returns (uint256 native, uint256 fragments) {
        uint48 elapsedTime = elapsedTimeFor(tokenId);
        uint48 daysPassed = elapsedTime / 1 days;
        native = daysPassed * TOKENS_PER_DAY;
        fragments = daysPassed * FRAGMENTS_PER_DAY;
    }

    function calculateRewards(uint256[] calldata tokenIds) public view returns (uint256 native, uint256 fragments) {
        if(tokenIds.length == 0) return (0, 0);
        for(uint256 i=0;i<tokenIds.length;++i) {
            (uint256 _native, uint256 _fragments) = calculateRewardsFor(tokenIds[i]);
            unchecked {
                native += _native;
                fragments += _fragments;
            }
        }
    }
    function claimRewards(uint256[] calldata tokenIds) external whenNotPaused {
        require(tokenIds.length > 0, "no_tokens_owned");
        (uint256 native, uint256 fragments) = calculateRewards(tokenIds);
        require(native > 0 || fragments > 0, "nothing_claimable");
        for(uint256 i=0;i<tokenIds.length;++i) {
            require(IERC721AQueryable(address(curiosities)).ownerOf(tokenIds[i]) == tx.origin, "not_token_owner");
            if(native > 0 || fragments > 0) {
                tokenRecords[uint16(tokenIds[i])].lastClaimTimestamp = uint48(block.timestamp);
                emit RewardsClaimed(tx.origin, tokenIds[i], native, fragments);
            }
        }
        if(native > 0) nativeToken.mintFor(tx.origin, native);
        if(fragments > 0) fragmentStorage[tx.origin] += fragments;
    }

    function getFragmentBalance() external view returns (uint256) {
        return fragmentStorage[tx.origin];
    }

    function flipStatus() external onlyOwner {
        if(paused()) _unpause();
        else _pause();
    }
}