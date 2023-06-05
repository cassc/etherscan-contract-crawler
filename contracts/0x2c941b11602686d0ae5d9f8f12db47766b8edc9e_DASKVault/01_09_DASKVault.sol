// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IKlub {
  function mint(address to, uint256 amount) external;
}

contract DASKVault is Ownable, IERC721Receiver {
  
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }

  uint public constant KLUBS_PER_DASK_PER_DAY = 10 * 1 ether;

  // tokenId to stake
  mapping(uint => Stake) public vault; 
  uint public totalStaked;

  IERC721Enumerable public dask;
  IKlub public klub;

  event Staked(address owner, uint tokenId, uint value);
  event Unstaked(address owner, uint tokenId, uint value);
  event Claimed(address owner, uint amount);

  constructor(address _dask, address _klub) { 
    dask = IERC721Enumerable(_dask);
    klub = IKlub(_klub);
  }

  function stake(uint[] calldata tokenIds) external {
    totalStaked += tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      uint tokenId = tokenIds[i];
      require(dask.ownerOf(tokenId) == msg.sender, "DASKVault: Only the owner of the DASK klub can stake it");
      require(vault[tokenId].tokenId == 0, "DASKVault: Token already staked");

      dask.transferFrom(msg.sender, address(this), tokenId);
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
      require(staked.owner == msg.sender, "DASKVault: Only the Staker can unstake it");

      delete vault[tokenId];
      emit Unstaked(account, tokenId, block.timestamp);
      dask.transferFrom(address(this), account, tokenId);
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
      require(staked.owner == account, "DASKVault: Only the Staker can claim");

      earned += KLUBS_PER_DASK_PER_DAY * (block.timestamp - staked.timestamp) / 1 days;

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
      require(stakedAt > 0, "DASKVault: Stake not found");

      earned += KLUBS_PER_DASK_PER_DAY * (block.timestamp - stakedAt) / 1 days;
    }

    return earned;
  }

  function balanceOf(address account) external view returns (uint) {
    uint balance;
    uint supply = dask.totalSupply();
    for(uint i = 0; i < supply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }

  function tokensOfOwner(address account) external view returns (uint[] memory ownerTokens) {
    uint supply = dask.totalSupply();
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
      require(from == address(0x0), "DASKVault: Can't receive tokens directly by minting");
      return IERC721Receiver.onERC721Received.selector;
    }
  
}