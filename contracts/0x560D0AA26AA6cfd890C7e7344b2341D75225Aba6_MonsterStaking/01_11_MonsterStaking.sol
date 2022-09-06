// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MonsterStaking is Ownable, ERC1155Holder, ReentrancyGuard {
    using SafeMath for uint256;

    bool public paused;
    uint256 public totalStakedCount;

    IERC1155 public monsterContract;
    mapping(address => mapping(uint256 => uint256)) stakedMonsterCount;
    mapping(uint256 => uint256) stakedTotalByType;

    uint256 constant MONSTER_A = 8; // octo
    uint256 constant MONSTER_B = 9; // dead pirate
    uint256 constant MONSTER_C = 10;
    uint256 constant MONSTER_D = 11;
    uint256 constant MONSTER_E = 12;
    uint256 constant MONSTER_F = 13;
    uint256 constant MONSTER_G = 14;

    mapping(address => uint8) selectedTribes;

    function getTribe(address address_) external view returns (uint8) {
        return selectedTribes[address_];
    }

    function setTribe(uint8 tribe) external {
        selectedTribes[msg.sender] = tribe;
    }

    function setGameObjectMakerContract(address address_) external onlyOwner {
        monsterContract = IERC1155(address_);
    }
    // Admin


    function pause(bool value) external onlyOwner {
        paused = value;
    }

    //Getters
    function getStakedBalance(address _address, uint256 monsterType)
        public
        view
        returns (uint256)
    {
        return stakedMonsterCount[_address][monsterType];
    }

    function getAllStakedBalances(address _address) public view returns (uint256[7] memory) {
        return [
            stakedMonsterCount[_address][MONSTER_A],
            stakedMonsterCount[_address][MONSTER_B],
            stakedMonsterCount[_address][MONSTER_C],
            stakedMonsterCount[_address][MONSTER_D],
            stakedMonsterCount[_address][MONSTER_E],
            stakedMonsterCount[_address][MONSTER_F],
            stakedMonsterCount[_address][MONSTER_G]
        ];
    }

    // user actions

    function stake(uint256 monsterType, uint256 num) external {
        require(num > 0, "requested stake quantity is 0");
        require(!paused, "Contract is paused");
        require(monsterType >= MONSTER_A, "unknown monster type");
        require(monsterContract.balanceOf(msg.sender, monsterType) > 0, "No monster to stake");
        require(
            monsterContract.balanceOf(msg.sender, monsterType) >= num,
            "You monster count need to match or exceed your intended stake count"
        );
        // transfer the monster to the contract
        monsterContract.safeTransferFrom(msg.sender, address(this), monsterType, num, "");
        stakedMonsterCount[msg.sender][monsterType] += num;
        totalStakedCount += num;
        stakedTotalByType[monsterType] += num;
    }

    function unstake(uint256 monsterType, uint256 num) external {
         require(num > 0, "requested unstake quantity is 0");
        require(!paused, "Contract is paused");
        require(
            stakedMonsterCount[msg.sender][monsterType] > 0,
            "You don't have any monster of that type staked"
        );
        require(
            stakedMonsterCount[msg.sender][monsterType] >= num,
            "You don't have enough staked monster to unstake that amount"
        );
        monsterContract.safeTransferFrom(address(this), msg.sender, monsterType, num, "");
        stakedMonsterCount[msg.sender][monsterType] -= num;
        totalStakedCount -= num;
        stakedTotalByType[monsterType] += num;
    }
}