// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

import "./BaseEnv.sol";

contract ERC721TimeLockStake is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, ERC721HolderUpgradeable, BaseEnv {
    struct Config {
        address stakeToken;
        uint32 startTime;
        uint32 endTime;
        uint32 period;
    }

    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;

    Config public config;

    address public admin;

    mapping(address => EnumerableMapUpgradeable.UintToUintMap) private tokenIdsPerAccount;

    function initialize(address _owner, address _admin) public initializer {
        __Ownable_init_unchained();
        transferOwnership(_owner);
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC721Holder_init_unchained();
        
        admin = _admin;
    }

    function upateAdmin(address _newAdmin) external onlyOwner {
        if (_newAdmin == address(0)) {
            revert Zero();
        }

        admin = _newAdmin;
    }

    function updateConfig(address _stakeToken, uint32 _startTime,  uint32 _endTime,  uint32 _period) external {
        if (msg.sender != admin) {
            revert NotAdmin();
        }

        config = Config(_stakeToken, _startTime, _endTime, _period);

        emit StakeConfigUpdate(_stakeToken, _startTime, _endTime, _period);
    }

    // View

    function balanceOf(address owner) external view returns (uint256) {
        return tokenIdsPerAccount[owner].length();
    }

    function stakeTokensOf(address owner) external view returns (uint256[] memory ids, uint256[] memory unlockTimes) {
        uint256 n = tokenIdsPerAccount[owner].length();
        ids = new uint[](n);
        unlockTimes = new uint[](n);
        for(uint i; i < n; i++) {
            (ids[i], unlockTimes[i]) = tokenIdsPerAccount[owner].at(i);
        }
    }

    function inStakePeriod() public view returns (bool) {
        return block.timestamp >= config.startTime && block.timestamp <= config.endTime;
    }

    // Mutable

    function stake(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        if (!inStakePeriod()) {
            revert StakeNotStart();
        }

        uint256 amount = tokenIds.length;

        if (amount == 0) {
            revert Zero();
        }

        EnumerableMapUpgradeable.UintToUintMap storage map = tokenIdsPerAccount[msg.sender];
        uint256 unlockTime = block.timestamp + config.period;
        if (amount > 0) {
            for (uint256 i; i < amount; i++) {
                IERC721Upgradeable(config.stakeToken).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
                map.set(tokenIds[i], unlockTime);
            }
        }

        emit Staked(msg.sender, amount, map.length());
    }

    function withdraw(uint256[] calldata tokenIds) external nonReentrant {
        
        uint256 amount = tokenIds.length;
        if (amount == 0) {
            revert Zero();
        }
        uint k;
        EnumerableMapUpgradeable.UintToUintMap storage map = tokenIdsPerAccount[msg.sender];
        for (uint256 i; i < amount; i++) {
            uint tokenId = tokenIds[i];
            (bool exists, uint unlockTime) = map.tryGet(tokenId);

            if (!exists) {
                continue;
            }

            if (unlockTime < block.timestamp) {
                k = k + 1;
                IERC721Upgradeable(config.stakeToken).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
                map.remove(tokenIds[i]);
            }
        }

        if (k == 0) {
            revert Zero();
        }

        emit Withdrawed(msg.sender, k);
    }
    // Admin

    function pause() external  {
        if(msg.sender != admin) {
            revert NotAdmin();
        }
        _pause();
    }

    function unpause() external onlyOwner {
        if(msg.sender != admin) {
            revert NotAdmin();
        }
        _unpause();
    }
}