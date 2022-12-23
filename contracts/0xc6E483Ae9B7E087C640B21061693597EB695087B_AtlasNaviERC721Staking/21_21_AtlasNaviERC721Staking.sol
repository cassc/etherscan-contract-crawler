// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AtlasNaviERC721Staking is IERC721Receiver, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    address public parentNFTAddress;
    uint256 public blockedOnStakeTime;

    struct Stake {
        uint tokenId;
        uint256 timestamp;
        uint withdrawTime;
    }

    struct StakeOwner {
        address stakeOwner;
        uint256 timestamp;
        uint withdrawTime;
    }

    // map staker address to stake details
    mapping (address => Stake[]) public stakes;

    //vreau sa intorc Stake si owner dupa tokenId
    mapping (uint256 => StakeOwner) public stakeOwner;

    function initialize(address nftAddress) public initializer {
        parentNFTAddress = nftAddress;
        __Ownable_init();
    }

    function setBlockedOnStakeTime(uint256 nrOfSeconds) public onlyOwner{
        blockedOnStakeTime = nrOfSeconds;
    }

    function stake(uint256 _tokenId) public {
        ERC721(parentNFTAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        stakes[msg.sender].push(Stake(_tokenId,block.timestamp, 0));
        stakeOwner[_tokenId] = StakeOwner(msg.sender, block.timestamp, 0);
        emit NFTStaked(msg.sender, _tokenId, block.timestamp);
    }

    function unstake(uint256 index) public {
        require (stakes[msg.sender].length > 0, "No stakes for this address");
        require(stakes[msg.sender].length-1 >= index, "Stake for this index not found!");
        require(stakes[msg.sender][index].withdrawTime ==  0,"Already unstaked!");
        require (block.timestamp - stakes[msg.sender][index].timestamp >= blockedOnStakeTime, "Unstake not possible.");
        stakes[msg.sender][index].withdrawTime = (block.timestamp - stakes[msg.sender][index].timestamp);
        stakeOwner[stakes[msg.sender][index].tokenId].withdrawTime = (block.timestamp - stakes[msg.sender][index].timestamp);
        ERC721(parentNFTAddress).safeTransferFrom(address(this), msg.sender, stakes[msg.sender][index].tokenId);
        emit NFTUnstaked(msg.sender, stakes[msg.sender][index].tokenId, block.timestamp);
    }

    function getStakesByAddress(address userAddress) public view returns (Stake [] memory){
        return stakes[userAddress];
    }

    function getStakesByTokenId(uint256 tokenId) public view returns(StakeOwner memory) {
        return stakeOwner[tokenId];
    }

    function onERC721Received(address addr1,address addr2 ,uint256 var1,bytes memory var2) override public pure returns (bytes4)  {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    event NFTStaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp);
    event NFTUnstaked(address indexed owner, uint256 indexed tokenId, uint256 timestamp);
}