// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBubbles {
    function mint(address recipient, uint amount) external;
}

contract AxolittlesStaking is Ownable {

    address public constant AXOLITTLES = 0xf36446105fF682999a442b003f2224BcB3D82067;
    address public immutable TOKEN;

    uint public emissionPerBlock;

    // These two are set in tandem, so if stakeBlock is 0 then stakeOwner will be address(0x0)
    // We check stakeOwner first so checking stakeBlock is unnecessary
    mapping(uint => uint) public stakeBlock; // For each tokenId, the block number when staking began. 0 if unstaked.
    mapping(uint => address) public stakeOwner; // For each tokenId, the owner of it

    event Stake(address indexed owner, uint tokenId);
    event Unstake(address indexed owner, uint tokenId);

    constructor(address _token, uint _emissionPerBlock) {
        TOKEN = _token;
        emissionPerBlock = _emissionPerBlock;
    }

    function stake(uint[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            IERC721(AXOLITTLES).transferFrom(msg.sender, address(this), tokenIds[i]);
            stakeBlock[tokenIds[i]] = block.number;
            stakeOwner[tokenIds[i]] = msg.sender;
            emit Stake(msg.sender, tokenIds[i]);
        }
    }

    function claim(uint[] memory tokenIds) external {
        uint totalReward = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            uint token = tokenIds[i];
            require(msg.sender == stakeOwner[token], "Only unstake your own axolittles");
            totalReward += (block.number - stakeBlock[token]) * emissionPerBlock;
            stakeBlock[token] = block.number;
        }
        IBubbles(TOKEN).mint(msg.sender, totalReward);    
    }

    function unstake(uint[] memory tokenIds) external {
        uint totalReward = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            uint token = tokenIds[i];
            address owner = stakeOwner[token];
            require(msg.sender == owner, "Only unstake your own axolittles");
            totalReward += (block.number - stakeBlock[token]) * emissionPerBlock;
            delete stakeOwner[token];
            delete stakeBlock[token];
            IERC721(AXOLITTLES).transferFrom(address(this), owner, token);
            emit Unstake(msg.sender, tokenIds[i]);
        }
        IBubbles(TOKEN).mint(msg.sender, totalReward);
    }

    function unclaimedRewards(uint[] memory tokenIds) external view returns (uint[] memory) {
        uint[] memory rewards = new uint[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            uint stakeBlockNumber = stakeBlock[tokenIds[i]];
            if (stakeBlockNumber == 0) {
                rewards[i] = 0;
            } else {
                rewards[i] = (block.number - stakeBlockNumber) * emissionPerBlock;
            }
        }
        return rewards;
    }

    function setEmissionPerBlock(uint _emissionPerBlock) external onlyOwner {
        emissionPerBlock = _emissionPerBlock;
    }
}