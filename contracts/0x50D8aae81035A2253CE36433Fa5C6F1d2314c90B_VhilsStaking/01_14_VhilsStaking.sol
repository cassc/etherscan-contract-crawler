// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// Vhils Staking
// Vhils + DRP + Pellar 2022

struct TokenInfo {
  uint8 state;
  bool locked;
  uint8[4] tearIdUsed;
  uint64 name;
  string uri;
}

interface ILAYERS is IERC721 {
  function getTokenInfo(uint16 _tokenId) external view returns (TokenInfo memory);
}

contract VhilsStaking is Ownable, ERC721Holder, ERC1155Holder {
  struct TierTear {
    uint8 level;
    uint256 startTime;
  }

  struct TierMedal {
    uint8 rank;
    uint256 startTime;
  }

  struct StakingInfo {
    address owner;
    TierTear tierTear;
    TierMedal tierMedal;
  }

  // variables
  address public vhilsNFT;
  address public vhilsTears;

  mapping(address => uint16[]) stakedLayers; // retrieve tokens staked by owner
  mapping(uint16 => StakingInfo) public stakingInfo;

  event Staked(uint16 indexed tokenId, address from, uint8 currentLevel, uint256 startTime, uint8 stakingType);
  event UnStaked(uint16 indexed tokenId, address from, uint8 newLevel, uint256 startTime, uint256 endTime, uint8 stakingType);

  constructor() {}

  function getStakedLayers(address _owner) external view returns (uint16[] memory) {
    return stakedLayers[_owner];
  }

  // stake for layers/tears
  function stake(uint16 _tokenId) public {
    require(ILAYERS(vhilsNFT).ownerOf(_tokenId) == msg.sender, "Require owner");

    // transfer
    ILAYERS(vhilsNFT).transferFrom(msg.sender, address(this), _tokenId);
    stakedLayers[msg.sender].push(_tokenId); // add to owner list after transfer
    stakingInfo[_tokenId].owner = msg.sender; // owner checkpoint
    // detect and stake
    TokenInfo memory tokenInfo = ILAYERS(vhilsNFT).getTokenInfo(_tokenId);

    uint256 _currentTime = block.timestamp;

    if (tokenInfo.state == 3) {  // tears
      stakingInfo[_tokenId].tierMedal.startTime = _currentTime;

      emit Staked(_tokenId, msg.sender, stakingInfo[_tokenId].tierMedal.rank, _currentTime, 1);
    } else { // layers
      uint8 stakingLevel = stakingInfo[_tokenId].tierTear.level;
      uint8 currentLevel = stakingLevel >= tokenInfo.state ? stakingLevel : tokenInfo.state;

      require(currentLevel < 3, "Exceed state");
      stakingInfo[_tokenId].tierTear.level = currentLevel;
      stakingInfo[_tokenId].tierTear.startTime = _currentTime;

      emit Staked(_tokenId, msg.sender, currentLevel, _currentTime, 0);
    }
  }

  // withdraw and get rewards
  function withdraw(uint16 _tokenId) public {
    require(msg.sender == stakingInfo[_tokenId].owner, "Require owner");

    ILAYERS(vhilsNFT).transferFrom(address(this), msg.sender, _tokenId);
    stakingInfo[_tokenId].owner = address(0); // owner checkpoint

    // detect and stake
    TokenInfo memory tokenInfo = ILAYERS(vhilsNFT).getTokenInfo(_tokenId);

    uint256 _currentTime = block.timestamp;

    if (tokenInfo.state == 3) {
      _withdrawForMedals(_tokenId);
      emit UnStaked(_tokenId, msg.sender, stakingInfo[_tokenId].tierMedal.rank, stakingInfo[_tokenId].tierMedal.startTime, _currentTime, 1);
    } else {
      _withdrawForTears(_tokenId);
      emit UnStaked(_tokenId, msg.sender, stakingInfo[_tokenId].tierTear.level, stakingInfo[_tokenId].tierTear.startTime, _currentTime, 0);
    }
  }

  function _withdrawForMedals(uint16 _tokenId) internal {
    // days: 24 * 60 * 60
    uint24[5] memory stakingDays = [
      10 * 24 * 60 * 60, //
      30 * 24 * 60 * 60,
      60 * 24 * 60 * 60,
      60 * 24 * 60 * 60,
      116 * 24 * 60 * 60
    ];

    uint256 durations = block.timestamp - stakingInfo[_tokenId].tierMedal.startTime;

    uint8 i = stakingInfo[_tokenId].tierMedal.rank;
    for (; i < stakingDays.length; i++) {
      if (durations < stakingDays[i]) {
        break;
      }

      durations -= stakingDays[i];
    }

    stakingInfo[_tokenId].tierMedal.rank = i; // update new rank
    _removeTokenFromStakedList(msg.sender, _tokenId);
  }

  function _withdrawForTears(uint16 _tokenId) internal {
    // days: 24 * 60 * 60
    uint24[3] memory stakingDays = [120 * 24 * 60 * 60, 70 * 24 * 60 * 60, 40 * 24 * 60 * 60];

    uint256 durations = block.timestamp - stakingInfo[_tokenId].tierTear.startTime;
    uint8 i = stakingInfo[_tokenId].tierTear.level;
    for (; i < stakingDays.length; i++) {
      if (durations < stakingDays[i]) {
        break;
      }
      IERC1155(vhilsTears).safeTransferFrom(address(this), msg.sender, 2, 1, "");
      durations -= stakingDays[i];
    }

    stakingInfo[_tokenId].tierTear.level = i; // update new level
    _removeTokenFromStakedList(msg.sender, _tokenId);
  }

  function batchStake(uint16[] memory _tokenIds) external {
    for (uint16 i = 0; i < _tokenIds.length; i++) {
      stake(_tokenIds[i]);
    }
  }

  function batchWithdraw(uint16[] memory _tokenIds) external {
    for (uint16 i = 0; i < _tokenIds.length; i++) {
      withdraw(_tokenIds[i]);
    }
  }

  /* View */
  function bindVhilsNFT(address _contract) external onlyOwner {
    vhilsNFT = _contract;
  }

  function bindVhilsTears(address _contract) external onlyOwner {
    vhilsTears = _contract;
  }

  // emergency unstake (owner)
  function forceWithdrawNFT(uint16[] memory _tokenIds) external onlyOwner {
    uint16 size = uint16(_tokenIds.length);
    for (uint16 i = 0; i < size; i++) {
      ILAYERS(vhilsNFT).transferFrom(address(this), msg.sender, _tokenIds[i]);
    }
  }

  /* internal */
  function _removeTokenFromStakedList(address _owner, uint16 _tokenId) internal {
    uint16 _index;
    for (uint16 i = 0; i < stakedLayers[_owner].length; i++) {
      if (stakedLayers[_owner][i] == _tokenId) {
        _index = i;
        break;
      }
    }
    uint16 _finalIndex = uint16(stakedLayers[_owner].length - 1);
    if (_index != _finalIndex) {
      stakedLayers[_owner][_index] = stakedLayers[_owner][_finalIndex]; // set current to same as final
    }
    stakedLayers[_owner].pop();
  }
}