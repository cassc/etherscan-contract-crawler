// SPDX-License-Identifier: MIT
/**

 ________  ___    ___ ________  ___  ___  _______   ________  _________   
|\   __  \|\  \  /  /|\   __  \|\  \|\  \|\  ___ \ |\   ____\|\___   ___\ 
\ \  \|\  \ \  \/  / | \  \|\  \ \  \\\  \ \   __/|\ \  \___|\|___ \  \_| 
 \ \   ____\ \    / / \ \  \\\  \ \  \\\  \ \  \_|/_\ \_____  \   \ \  \  
  \ \  \___|/     \/   \ \  \\\  \ \  \\\  \ \  \_|\ \|____|\  \   \ \  \ 
   \ \__\  /  /\   \    \ \_____  \ \_______\ \_______\____\_\  \   \ \__\
    \|__| /__/ /\ __\    \|___| \__\|_______|\|_______|\_________\   \|__|
          |__|/ \|__|          \|__|                  \|_________|        
                                                                          


 * @title AdventurerStaking
 * AdventurerStaking - a contract for staking PX Quest Adventurers
 */

pragma solidity ^0.8.11;

import "./IAdventurerStaking.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAdventurer {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IChronos {
    function grantChronos(address to, uint256 amount) external;
}

contract AdventurerStaking is IAdventurerStaking, Ownable, ERC721Holder {
    IAdventurer public adventurerContract;
    IChronos public chronosContract;

    // NFT tokenId to time staked and owner's address
    mapping(uint64 => StakedToken) public stakes;

    uint64 private constant NINETY_DAYS = 7776000;
    uint64 public LOCK_IN = 0;
    bool grantChronos = true;
    uint256 public constant BASE_RATE = 5 ether;

    constructor(
        address _adventurerContract,
        address _chronosContract,
        address _ownerAddress
    ) {
        require(
            _adventurerContract != address(0),
            "nft contract cannot be 0x0"
        );
        require(
            _chronosContract != address(0),
            "chronos contract cannot be 0x0"
        );
        adventurerContract = IAdventurer(_adventurerContract);
        chronosContract = IChronos(_chronosContract);
        if (_ownerAddress != msg.sender) {
            transferOwnership(_ownerAddress);
        }
    }

    function viewStakes(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokens = new uint256[](7500);
        uint256 tookCount = 0;
        for (uint64 i = 0; i < 7500; i++) {
            if (stakes[i].user == _address) {
                _tokens[tookCount] = i;
                tookCount++;
            }
        }
        uint256[] memory trimmedResult = new uint256[](tookCount);
        for (uint256 j = 0; j < trimmedResult.length; j++) {
            trimmedResult[j] = _tokens[j];
        }
        return trimmedResult;
    }

    function stake(uint64 tokenId) public override {
        stakes[tokenId] = StakedToken(msg.sender, uint64(block.timestamp));
        emit StartStake(msg.sender, tokenId);
        adventurerContract.safeTransferFrom(
            msg.sender,
            address(this),
            uint256(tokenId)
        );
    }

    function groupStake(uint64[] memory tokenIds) external override {
        for (uint64 i = 0; i < tokenIds.length; ++i) {
            stake(tokenIds[i]);
        }
    }

    function unstake(uint64 tokenId) public override {
        require(stakes[tokenId].user != address(0), "tokenId not staked");
        require(
            stakes[tokenId].user == msg.sender,
            "sender didn't stake token"
        );
        uint64 stakeLength = uint64(block.timestamp) -
            stakes[tokenId].timeStaked;
        require(
            stakeLength > LOCK_IN, "can not remove token until lock-in period is over"
        );
        if (grantChronos) {
            uint256 calcrew = (BASE_RATE * uint256(stakeLength)) /86400;
            chronosContract.grantChronos(msg.sender, calcrew);
        }
        emit Unstake(
            msg.sender,
            tokenId,
            stakeLength > NINETY_DAYS,
            stakeLength
        );
        delete stakes[tokenId];
        adventurerContract.safeTransferFrom(
            address(this),
            msg.sender,
            uint256(tokenId)
        );
    }

    function groupUnstake(uint64[] memory tokenIds) external override {
        for (uint64 i = 0; i < tokenIds.length; ++i) {
            unstake(tokenIds[i]);
        }
    }

    function setGrantChronos(bool _grant) external onlyOwner {
        grantChronos = _grant;
    }

    function setLockIn(uint64 lockin) external onlyOwner {
        LOCK_IN = lockin;
    }    
}