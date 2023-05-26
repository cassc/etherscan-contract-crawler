// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./POWERSTONES.sol";

contract METAG_STAKING is Ownable, IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet; 

    mapping(uint => address) public ownership;
    mapping(uint => uint) public stakeTime;
    mapping(address => uint) public lastWithdraw;
    mapping(address => uint[]) public _qty;
    mapping(uint256 => Stake) public stakes;
    mapping(address => EnumerableSet.UintSet) private stakedTokens;

    bool public paused = false;
    uint public tokensPerBlock;
    uint256 public nonce = 0;
    uint nullToken = 1 ether;
    uint256 public lockupPeriod = 604800; // 1 week

    IERC721 public NFT;
    POWERSTONES public TOKEN;

    struct Stake {
        uint256 lockupExpires;
        uint256 lastClaimedBlock;
    }

    struct RewardChanged {
        uint256 block;
        uint256 rewardPerBlock;
    }

    RewardChanged[] rewardChanges;

    modifier notPaused(){
        require(!paused, "PAUSED");
        _;
    }

    constructor(uint128 _tokensPerBlock) {
        tokensPerBlock = _tokensPerBlock;
    }

    function getStaked() public view returns (uint) {
        return nonce;
    }

    function setTokensPerBlock(uint new_) external onlyOwner {
        tokensPerBlock = new_;
    }

    function setLockupPeriod(uint new_) external onlyOwner {
        lockupPeriod = new_;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function setNFTAddress(address new_) external onlyOwner {
        NFT = IERC721(new_);
    }

    function setCOINAddress(address new_) external onlyOwner {
        TOKEN = POWERSTONES(new_);
    }

    function getAssetsByHolder(address holder) public view returns (uint[] memory){
        return _qty[holder];
    }

    function claimRewards(uint256[] calldata tokenIds) external notPaused {
        require(tokenIds.length > 0, "ClaimRewards: missing token ids");

        uint256 rewards;

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                stakedTokens[msg.sender].contains(tokenIds[i]), 
                "ClaimRewards: token not staked"
            );
            require(
                stakes[tokenIds[i]].lockupExpires < block.timestamp, 
                "ClaimRewards: lockup period not expired"
            );            
            
            rewards += calculateRewards(tokenIds[i]);
            stakes[tokenIds[i]].lastClaimedBlock = uint128(block.number);
            stakes[tokenIds[i]].lockupExpires = uint128(block.timestamp + lockupPeriod);
        }

        TOKEN.mintTo(_msgSender(), rewards);
    }  

    function calculateRewards(uint256 tokenID) public view returns (uint256) {
        require(stakes[tokenID].lastClaimedBlock != 0, "token not staked");
        require(tokenID != nullToken, "err: token not staked");

        uint256 rewards;
        uint256 blocksPassed;

        uint256 lastClaimedBlock = stakes[tokenID].lastClaimedBlock;

        uint256 from;
        uint256 last;

        for(uint256 i=0; i < rewardChanges.length; i++) {
            bool hasNext = i+1 < rewardChanges.length;

            from = rewardChanges[i].block >= lastClaimedBlock ? 
                   rewardChanges[i].block : 
                   lastClaimedBlock;
            
            last = hasNext ? 
                   (rewardChanges[i+1].block >= lastClaimedBlock ? 
                      rewardChanges[i+1].block : 
                      from 
                   ) : 
                   block.number;

            blocksPassed = last - from;
            rewards += rewardChanges[i].rewardPerBlock * blocksPassed;         
        }
        return rewards;
    }  

    function stake(uint256[] calldata tokenIds) external notPaused {
        require(tokenIds.length > 0, "Stake: amount prohibited");

        for (uint256 i; i < tokenIds.length; i++) {
            require(NFT.ownerOf(tokenIds[i]) == msg.sender, "Stake: sender not owner");

            NFT.transferFrom(msg.sender, address(this), tokenIds[i]);

            stakes[tokenIds[i]] = Stake(uint128(block.timestamp + lockupPeriod), uint128(block.number));
            stakedTokens[msg.sender].add(tokenIds[i]);
            _qty[msg.sender].push(tokenIds[i]);
            nonce++;
        }
        
        rewardChanges.push(RewardChanged(uint256(block.number), tokensPerBlock / nonce));
    }   

    function unstake(uint256[] calldata tokenIds) external notPaused {
        require(tokenIds.length > 0, "Unstake: amount prohibited");

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                stakedTokens[msg.sender].contains(tokenIds[i]), 
                "Unstake: token not staked"
            );
            
            stakedTokens[msg.sender].remove(tokenIds[i]);
            delete stakes[tokenIds[i]];
            removeToken(tokenIds[i]);
            NFT.transferFrom(address(this), msg.sender, tokenIds[i]);
            nonce--;
        }

        rewardChanges.push(RewardChanged(uint256(block.number), tokensPerBlock / (nonce == 0 ? 1 : nonce)));
    }

    function removeToken(uint tokenId) internal {
        for(uint i=0;i<_qty[_msgSender()].length;i++){
            if(_qty[_msgSender()][i] == tokenId){
                _qty[_msgSender()][i] = nullToken;
                break;
            }
        }
    }

    function onERC721Received(address operator, address, uint256, bytes memory) public view override returns (bytes4) {
        require(operator == address(this), "Operator not staking contract");

        return this.onERC721Received.selector;
    }

}