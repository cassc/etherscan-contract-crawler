// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./GRFToken.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TenFTGiraffesStake is  Ownable {
 // uint256 public totalStaked;
  uint256 private rewardsPerDay = 10000000000000000000;//10 ether
  // struct to store a stake's token, owner, and earning values
 
    ///NEWWW
    mapping(uint256 => uint256) private stakeStarted;
    mapping(uint256 => uint256) private stakingTotal;
    bool public stakeOpen = false;
    event Staked(uint256 indexed tokenId);
    event Unstaked(uint256 indexed tokenId);
    event Expelled(uint256 indexed tokenId);

    IERC721Enumerable nft;
    GRF token;

     constructor(IERC721Enumerable _nft, GRF _token) { 
            nft = _nft;
            token = _token;
        }


    function toggleStaking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
        _toggleStaking(msg.sender,tokenIds[i]);
        }
    }
    function _toggleStaking(address account,uint256 tokenId) internal{
        require(stakeOpen, "10FTGiraffes: staking closed");
        require(nft.ownerOf(tokenId) == account,"10FTGiraffes: Not owner");
        uint256 start = stakeStarted[tokenId];
        if (start == 0) {
        stakeStarted[tokenId] = block.timestamp;
        emit Staked(tokenId);
        } else {
        stakingTotal[tokenId] += block.timestamp - start;
        stakeStarted[tokenId] = 0;
        emit Unstaked(tokenId);
        }
    }

    function claim(uint256[] calldata tokenIds) external {
        _claimforTokens(msg.sender, tokenIds);
    }

    function _claimforTokens(address account,uint256[] calldata tokenIds) internal {
        uint256 tokenId;
        uint256 start;
        uint256 current;
        uint256 totaltimeforToken;
        uint256 totalforTokens;
      for (uint i = 0; i < tokenIds.length; i++) {
        tokenId = tokenIds[i];
        require(nft.ownerOf(tokenId) == account,"10FTGiraffes: Not owner");
        start = stakeStarted[tokenId];
        if (start != 0) {
        current = block.timestamp - start;
        stakeStarted[tokenId]=block.timestamp;
        }
        stakingTotal[tokenId]=0;
        totaltimeforToken = current + stakingTotal[tokenId];
        totalforTokens += rewardsPerDay *totaltimeforToken / 86400;

     }
      if (totalforTokens > 0) {
          token.mint(account, totalforTokens);
        }
  }



    function earningInfo(uint256 tokenId) external view returns (
            bool staking,
            uint256 current,
            uint256 total,
            uint256 start
        ) {
            start = stakeStarted[tokenId];

            if (start != 0) {
            staking = true;
            current = block.timestamp - start;
            }
            total = current + stakingTotal[tokenId];
        }

   
    function earningInfoForTokens(uint256[] calldata tokenIds) external view returns (
        bool[] memory staking,
        uint256[] memory currents,
        uint256  totalforTokens,
        uint256[] memory starts
    ) {
        uint256 tokenId;
        uint256  start;
        uint256 current;
        staking=new bool[](tokenIds.length);
        starts=new uint256[](tokenIds.length);
        currents=new uint256[](tokenIds.length);
      for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            start = stakeStarted[tokenId];
            starts[i]=start;
        if (start != 0) {
            current = block.timestamp - start;
            currents[i]=current;
            staking[i]=true;
        }else{
            currents[i]=0;
            staking[i]=false;    
        }
         totalforTokens += rewardsPerDay *(current + stakingTotal[tokenId] )/ 86400;
        }
    }

  
        function setStakingOpen(bool open) external onlyOwner {
            stakeOpen = open;
        }
        function expelFromStake(uint256 tokenId) external onlyOwner {
            require(stakeStarted[tokenId] != 0, "10FT Giraffes: not staking");

            stakingTotal[tokenId] += block.timestamp - stakeStarted[tokenId];
            stakeStarted[tokenId] = 0;

            emit Staked(tokenId);
            emit Expelled(tokenId);
        }
  
}