// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Context, Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {INFTLocker} from "./interfaces/INFTLocker.sol";
import {ILockMigrator} from "./interfaces/ILockMigrator.sol";

contract LockMigrator is ILockMigrator, Ownable, Pausable, ReentrancyGuard {
    bytes32 public merkleRoot;
    uint256 public migrationReward = 10 * 1e18;

    IERC20 public maha;
    IERC20 public scallop;
    INFTLocker public mahaxLocker;

    uint256 internal constant WEEK = 1 weeks;

    mapping(uint256 => bool) public isTokenIdMigrated;
    mapping(uint256 => bool) public isTokenIdBanned;
    mapping(address => bool) public isAddressBanned;

    constructor(
        bytes32 _merkleRoot,
        IERC20 _maha,
        IERC20 _scallop,
        INFTLocker _mahaxLocker
    ) {
        merkleRoot = _merkleRoot;
        maha = _maha;
        scallop = _scallop;
        mahaxLocker = _mahaxLocker;
    }

    function setMigrationReward(uint256 reward) external override onlyOwner {
        emit MigrationRewardChanged(migrationReward, reward);
        migrationReward = reward;
    }

    function _migrateLock(
        uint256 _value,
        uint256 _endDate,
        uint256 _tokenId,
        address _who,
        uint256 _mahaReward,
        uint256 _scallopReward,
        bytes32[] memory proof
    ) internal nonReentrant whenNotPaused returns (uint256) {
        require(_endDate >= (block.timestamp + 2 * WEEK), "end date expired");
        require(_tokenId != 0, "tokenId is 0");
        require(!isTokenIdMigrated[_tokenId], "tokenId already migrated");
        require(!isTokenIdBanned[_tokenId], "tokenId banned");
        require(!isAddressBanned[_who], "owner banned");

        bool _isLockvalid = isLockValid(
            _value,
            _endDate,
            _who,
            _tokenId,
            _mahaReward,
            _scallopReward,
            proof
        );
        require(_isLockvalid, "Migrator: invalid lock");

        uint256 _lockDuration = _endDate - block.timestamp;
        uint256 newTokenId = mahaxLocker.migrateTokenFor(
            _value,
            _lockDuration,
            _who
        );
        require(newTokenId > 0, "Migrator: migration failed");

        isTokenIdMigrated[_tokenId] = true;

        if (_mahaReward > 0) maha.transfer(_who, _mahaReward);
        if (_scallopReward > 0) scallop.transfer(_who, _scallopReward);
        if (migrationReward > 0) maha.transfer(msg.sender, migrationReward);

        return newTokenId;
    }

    function migrateLock(
        uint256 _value,
        uint256 _endDate,
        uint256 _tokenId,
        address _who,
        uint256 _mahaReward,
        uint256 _scallopReward,
        bytes32[] memory _proof
    ) external override returns (uint256) {
        return
            _migrateLock(
                _value,
                _endDate,
                _tokenId,
                _who,
                _mahaReward,
                _scallopReward,
                _proof
            );
    }

    function migrateLocks(
        uint256[] memory _value,
        uint256[] memory _endDate,
        uint256[] memory _tokenId,
        address[] memory _who,
        uint256[] memory _mahaReward,
        uint256[] memory _scallopReward,
        bytes32[][] memory proof
    ) external {
        for (uint256 index = 0; index < _value.length; index++) {
            _migrateLock(
                _value[index],
                _endDate[index],
                _tokenId[index],
                _who[index],
                _mahaReward[index],
                _scallopReward[index],
                proof[index]
            );
        }
    }

    function isLockValid(
        uint256 _value,
        uint256 _endDate,
        address _owner,
        uint256 _tokenId,
        uint256 _mahaReward,
        uint256 _scallopReward,
        bytes32[] memory proof
    ) public view override returns (bool) {
        bytes32 leaf = keccak256(
            abi.encode(
                _value,
                _endDate,
                _owner,
                _tokenId,
                _mahaReward,
                _scallopReward
            )
        );
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function refund() external onlyOwner {
        maha.transfer(msg.sender, maha.balanceOf(address(this)));
        scallop.transfer(msg.sender, scallop.balanceOf(address(this)));
    }

    function toggleBanID(uint256 id) external onlyOwner {
        isTokenIdBanned[id] = !isTokenIdBanned[id];
    }

    function togglePause() external onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    function toggleBanOwner(address _who) external onlyOwner {
        isAddressBanned[_who] = !isAddressBanned[_who];
    }
}