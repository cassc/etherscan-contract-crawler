/*** Smart Contract By
 *                 _                 _
 *     ___   __ _ | |_  __ _   __ _ (_)
 *    / __| / _` || __|/ _` | / _` || |
 *    \__ \| (_| || |_| (_| || (_| || |
 *    |___/ \__,_| \__|\__,_| \__, ||_|
 *                               |_|
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BapesClanStaker is Ownable {
  struct StakedBape {
    address owner;
    uint256 tokenId;
    uint256 timestamp;
  }

  IERC721 private bapesClanG1;

  mapping(address => StakedBape[]) private stakes;

  bool isStakingPaused = true;

  constructor() {
    bapesClanG1 = IERC721(0x8Ce66fF0865570D1ff0BB0098Fa41B4dc61E02e6);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function stake(uint256 _tokenId) external {
    require(!isStakingPaused, "Staking is paused.");

    bapesClanG1.safeTransferFrom(msg.sender, address(this), _tokenId);

    stakes[msg.sender].push(StakedBape(msg.sender, _tokenId, block.timestamp));
  }

  function unstake(uint256 _tokenId) external {
    uint256 senderStakes = stakes[msg.sender].length;

    require(senderStakes > 0, "Address has no stakes.");

    for (uint256 i = 0; i < senderStakes; i++) {
      if (stakes[msg.sender][i].tokenId == _tokenId && stakes[msg.sender][i].timestamp != 0) {
        uint256 elapsedMins = (block.timestamp - stakes[msg.sender][i].timestamp) / 60;
        uint256 elapsedDays = elapsedMins / 1440;

        require(elapsedDays >= 90, "Can not unstake before 90 days.");

        bapesClanG1.safeTransferFrom(address(this), msg.sender, _tokenId);

        stakes[msg.sender][i].timestamp = 0;

        break;
      }

      if (i == senderStakes - 1) {
        revert("Provided token id not staked.");
      }
    }
  }

  function getStakes(address _address) external view returns (StakedBape[] memory) {
    uint256 addressStakes = stakes[_address].length;

    require(addressStakes > 0, "Address has no stakes.");

    StakedBape[] memory res = new StakedBape[](addressStakes);

    for (uint256 i = 0; i < addressStakes; i++) {
      if (stakes[_address][i].timestamp != 0) {
        res[i] = StakedBape(stakes[_address][i].owner, stakes[_address][i].tokenId, stakes[_address][i].timestamp);
      }
    }

    return res;
  }

  function pauseStaking(bool _state) external onlyOwner {
    isStakingPaused = _state;
  }
}