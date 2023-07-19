// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IKlub {
  function mint(address to, uint256 amount) external;
}

contract TombVault is Ownable, IERC721Receiver {
  
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }

  uint public KLUBS_PER_TOMB_PER_DAY = 5 * 1 ether;

  // tokenId to stake
  mapping(uint => Stake) public vault; 
  uint public totalStaked;

  IERC721Enumerable public tomb = IERC721Enumerable(0x40f8719f2919a5DEDD2D5A67065df6EaC65c149C);
  IKlub public klub = IKlub(0xa0DB234a35AaF919b51E1F6Dc21c395EeF2F959d);

  event Staked(address owner, uint tokenId, uint value);
  event Unstaked(address owner, uint tokenId, uint value);
  event Claimed(address owner, uint amount);

  constructor() { 
  }

  function setTomb(address _tomb) external onlyOwner {
    tomb = IERC721Enumerable(_tomb);
  }
  function setKlub(address _klub) external onlyOwner {
    klub = IKlub(_klub);
  }
  function setKLUBS_PER_TOMB_PER_DAY(uint _KLUBS_PER_TOMB_PER_DAY) external onlyOwner {
    KLUBS_PER_TOMB_PER_DAY = _KLUBS_PER_TOMB_PER_DAY * 1 ether;
  }

  function stake(uint[] calldata tokenIds) external {
    totalStaked += tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      uint tokenId = tokenIds[i];
      require(tomb.ownerOf(tokenId) == msg.sender, "TombVault: Only the owner of the tomb klub can stake it");
      require(vault[tokenId].tokenId == 0, "TombVault: Token already staked");

      tomb.transferFrom(msg.sender, address(this), tokenId);
      emit Staked(msg.sender, tokenId, block.timestamp);

      vault[tokenId] = Stake({
        owner: msg.sender,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });
    }
  }

  function _unstakeMany(address account, uint[] calldata tokenIds) internal {
    totalStaked -= tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      uint tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == msg.sender, "TombVault: Only the Staker can unstake it");

      delete vault[tokenId];
      emit Unstaked(account, tokenId, block.timestamp);
      tomb.transferFrom(address(this), account, tokenId);
    }
  }

  function claim(uint[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, false);
  }

  function claimForAddress(address account, uint[] calldata tokenIds) external {
      _claim(account, tokenIds, false);
  }

  function unstake(uint[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, true);
  }

  function _claim(address account, uint[] calldata tokenIds, bool _unstake) internal {
    uint earned;
    for (uint i = 0; i < tokenIds.length; i++) {
      uint tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "TombVault: Only the Staker can claim");

      earned += KLUBS_PER_TOMB_PER_DAY * (block.timestamp - staked.timestamp) / 1 days;

      vault[tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(block.timestamp)
      });

    }
    if (earned > 0) {
      klub.mint(account, earned);
    }
    if (_unstake) {
      _unstakeMany(account, tokenIds);
    }
    emit Claimed(account, earned);
  }

  function unclamiedEarnings(uint[] calldata tokenIds) external view returns (uint) {
     uint earned;
     for (uint i = 0; i < tokenIds.length; i++) {
      uint tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      uint stakedAt = staked.timestamp;
      require(stakedAt > 0, "TombVault: Stake not found");

      earned += KLUBS_PER_TOMB_PER_DAY * (block.timestamp - stakedAt) / 1 days;
    }

    return earned;
  }

  function balanceOf(address account) external view returns (uint) {
    uint balance;
    uint supply = tomb.totalSupply();
    for(uint i = 0; i < supply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }

  function tokensOfOwner(address account) external view returns (uint[] memory ownerTokens) {
    uint supply = tomb.totalSupply();
    uint[] memory tmp = new uint[](supply);

    uint index;
    for(uint tokenId = 0; tokenId < supply; tokenId++) {
      if (vault[tokenId].owner == account) {
        tmp[index] = vault[tokenId].tokenId;
        index +=1;
      }
    }

    uint[] memory tokens = new uint[](index);
    for(uint i = 0; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  function onERC721Received(
        address,
        address from,
        uint,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "TombVault: Can't receive tokens directly by minting");
      return IERC721Receiver.onERC721Received.selector;
    }
  
}