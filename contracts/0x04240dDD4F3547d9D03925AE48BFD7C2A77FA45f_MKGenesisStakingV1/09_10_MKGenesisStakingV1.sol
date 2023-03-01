// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/IMKLockRegistry.sol";
import "./interfaces/IPeach.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "hardhat/console.sol";

contract MKGenesisStakingV1 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IMKLockRegistry public mk;
    IMKLockRegistry public db;
    IPeach public peach;
    mapping(uint256 => address) public staked;
    uint256 public constant NUM_WUKONGS = 2222;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address mkAddr,
        address dbAddr,
        address peachAddr
    ) public reinitializer(1) {
        __Ownable_init();
        __ReentrancyGuard_init();
        mk = IMKLockRegistry(mkAddr);
        db = IMKLockRegistry(dbAddr);
        peach = IPeach(peachAddr);
    }

    function isBaepe(uint256 tokenId) internal pure returns (bool) {
        return tokenId > NUM_WUKONGS;
    }

    function stake(
        uint256[] calldata tokenIDs,
        uint256 ts,
        bytes memory sig,
        uint256[] calldata stakingTokenIDs
    ) external {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (isBaepe(tokenIDs[i])) {
                uint256 dbID = tokenIDs[i] - NUM_WUKONGS;
                require(
                    db.ownerOf(dbID) == msg.sender,
                    "Owner check failed"
                );
                db.lock(dbID);
            } else {
                require(
                    mk.ownerOf(tokenIDs[i]) == msg.sender,
                    "Owner check failed"
                );
                mk.lock(tokenIDs[i]);
            }
            staked[tokenIDs[i]] = msg.sender;
        }
        for (uint256 i = 0; i < stakingTokenIDs.length; i++) {
            peach.claim(stakingTokenIDs);
            staked[stakingTokenIDs[i]] = msg.sender;
        }
        peach.stake(tokenIDs, ts, sig);
    }

    function claim(uint256[] calldata tokenIDs) public nonReentrant {
        uint256 sumClaimable;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (isBaepe(tokenIDs[i])) {
                require(
                    db.ownerOf(tokenIDs[i] - NUM_WUKONGS) == msg.sender,
                    "Owner check failed"
                );
            } else {
                require(
                    mk.ownerOf(tokenIDs[i]) == msg.sender,
                    "Owner check failed"
                );
            }
            sumClaimable += peach.claimable(tokenIDs[i]);
        }

        peach.claim(tokenIDs);
        peach.transfer(msg.sender, sumClaimable);
    }

    function claimable(uint256 tokenId) public view returns (uint256 sum) {
        return peach.claimable(tokenId);
    }

    function claimable(uint256[] calldata tokenIds) public view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokens[i] = peach.claimable(tokenIds[i]);
        }
        return tokens;
    }
    function stakedWith(uint256[] calldata tokenIds, address addr) public view returns (bool[] memory) {
        bool[] memory ret = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ret[i] = (peach.staker(tokenIds[i]) == addr);
        }
        return ret;
    }

    function unstake(uint256[] calldata tokenIDs, uint256[] calldata positions)
        external
    {
        claim(tokenIDs);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            if (isBaepe(tokenIDs[i])) {
                db.unlock(tokenIDs[i] - NUM_WUKONGS, positions[i]);
            } else {
                mk.unlock(tokenIDs[i], positions[i]);
            }
            staked[tokenIDs[i]] = address(0);
        }
    }

    // erc20 recoverer
    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}