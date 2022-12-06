// SPDX-License-Identifier: UNLICENSED

// Crafted with ❤️ by [ @esawwh (1619058420), @dankazenoff ] @ HOMA;

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface Valentine {
  function ownerOf(uint256 tokenId) external view returns (address);
  function transferFrom(address sender, address recipient, uint256 tokenId) external;    
  function balanceOf(address owner) external view returns (uint256);
}

contract StakeValentine is Ownable {
  Valentine private ValentineERC721;

  bool private canWhalesStake = false;
  bool private canHoldersStake = false;
  uint256 private minimumStakeDurationInSeconds;

  struct StakeMetadata {
    uint256 tokenId;
    uint256 startTimestamp;
    uint256 minimumStakeDurationEndTimestamp;
    address stakedBy;
    bool active;
  }
  
  mapping(uint256 => StakeMetadata) public stakedTokens;

  event Staked(address indexed from, StakeMetadata stakedInfo);
  event Claimed(address indexed from, StakeMetadata stakedInfo);

  constructor(address _valentineAddress, uint256 _minimumStakeDurationInSeconds) {
    require(_valentineAddress != address(0), "Valentine to stake needs to have non-zero address.");                
    ValentineERC721 = Valentine(_valentineAddress);
    minimumStakeDurationInSeconds = _minimumStakeDurationInSeconds;
  }

  function stakeToken(uint256[] calldata _tokenIds) external {
    require(_tokenIds.length > 0, "NFT's to stake should be greater than 0");
    require(canHoldersStake || (canWhalesStake && ValentineERC721.balanceOf(msg.sender) >= 5));

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      require(ValentineERC721.ownerOf(_tokenIds[i]) == msg.sender);

      StakeMetadata memory stakeInfo = StakeMetadata({                
        startTimestamp: block.timestamp,
        minimumStakeDurationEndTimestamp: block.timestamp + minimumStakeDurationInSeconds,
        stakedBy: msg.sender,
        tokenId: _tokenIds[i],
        active: true
      });

      stakedTokens[_tokenIds[i]] = stakeInfo;

      ValentineERC721.transferFrom(msg.sender, address(this), _tokenIds[i]);

      emit Staked(msg.sender, stakeInfo);
    }
  }    

  function withdrawToken(uint256[] calldata _tokenIds) external {
    require(_tokenIds.length > 0, "NFT's to withdraw should be greater than 0");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      StakeMetadata memory stakeInfo = stakedTokens[_tokenIds[i]];
      require(stakeInfo.active == true, "This token is not staked");
      require((stakeInfo.stakedBy == msg.sender && stakeInfo.minimumStakeDurationEndTimestamp < block.timestamp) 
      || msg.sender == owner());

      StakeMetadata memory defaultStakeInfo;
      stakedTokens[_tokenIds[i]] = defaultStakeInfo;

      ValentineERC721.transferFrom(address(this), stakeInfo.stakedBy, _tokenIds[i]);

      emit Claimed(stakeInfo.stakedBy, stakeInfo);
    }
  }

  function setCanWhalesStake(bool _can) external onlyOwner {
    canWhalesStake = _can;
  }

  function getCanWhalesStake() external view returns (bool) {
    return canWhalesStake;
  }

  function setCanHoldersStake(bool _can) external onlyOwner {
    canHoldersStake = _can;
  }

  function getCanHoldersStake() external view returns (bool) {
    return canHoldersStake;
  }

  function setMinimumStakeDuration(uint256 _durationInSeconds) external onlyOwner {
    minimumStakeDurationInSeconds = _durationInSeconds;
  }

  function getMinimumStakeDuration() external view returns (uint256) {
    return minimumStakeDurationInSeconds;
  }
}