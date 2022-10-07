// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DCNTStaking is
  Initializable,
  Ownable,
  ReentrancyGuard,
  IERC721Receiver
{
  uint256 public totalStaked;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }

  event NFTStaked(address owner, uint256 tokenId, uint256 value);
  event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);

  address public nftAddress;
  address public erc20Address;
  uint256 public vaultStart;
  uint256 public vaultEnd;
  uint256 public totalClaimed;
  uint256 public totalSupply;

  // maps tokenId to stake
  mapping(uint256 => Stake) public vault;

  function initialize(
    address _owner,
    address _nft,
    address _token,
    uint256 _vaultDuration,
    uint256 _totalSupply
  ) public initializer {
    _transferOwnership(_owner);
    nftAddress = _nft;
    erc20Address = _token;
    vaultStart = block.timestamp;
    vaultEnd = vaultStart + (_vaultDuration * 1 days);
    totalSupply = _totalSupply;
  }

  function stake(uint256[] calldata tokenIds) external nonReentrant {
    uint256 tokenId;
    totalStaked += tokenIds.length;
    for (uint256 i; i != tokenIds.length; i++) {
      tokenId = tokenIds[i];
      require(vault[tokenId].owner == address(0), "already staked");
      require(
        IERC721(nftAddress).ownerOf(tokenId) == msg.sender,
        "not your token"
      );
      require(
        IERC721(nftAddress).getApproved(tokenId) == address(this),
        "not approved for transfer"
      );

      IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
      emit NFTStaked(msg.sender, tokenId, block.timestamp);

      vault[tokenId] = Stake({
        owner: msg.sender,
        tokenId: uint24(tokenId),
        timestamp: uint48(min(block.timestamp, vaultEnd))
      });
    }
  }

  function _unstakeMany(address account, uint256[] calldata tokenIds) internal {
    uint256 tokenId;
    totalStaked -= tokenIds.length;
    for (uint256 i; i != tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == msg.sender, "not an owner");

      delete vault[tokenId];
      emit NFTUnstaked(account, tokenId, block.timestamp);
      IERC721(nftAddress).safeTransferFrom(address(this), account, tokenId);
    }
  }

  function claim(uint256[] calldata tokenIds) external nonReentrant {
    _claim(msg.sender, tokenIds, false);
  }

  function claimForAddress(address account, uint256[] calldata tokenIds)
    external
    nonReentrant
  {
    _claim(account, tokenIds, false);
  }

  function unstake(uint256[] calldata tokenIds) external nonReentrant {
    _claim(msg.sender, tokenIds, true);
  }

  function _claim(
    address account,
    uint256[] calldata tokenIds,
    bool _unstake
  ) internal {
    uint256 tokenId;
    uint256 earned = 0;

    for (uint256 i; i != tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");
      uint256 stakedAt = staked.timestamp;
      uint256 currentTime = min(block.timestamp, vaultEnd);

      earned += calculateEarn(stakedAt);

      vault[tokenId] = Stake({
        owner: account,
        tokenId: uint24(tokenId),
        timestamp: uint48(currentTime)
      });
    }
    if (earned > 0) {
      IERC20(erc20Address).transfer(account, earned);
      totalClaimed += earned;
    }
    if (_unstake) {
      _unstakeMany(account, tokenIds);
    }
    emit Claimed(account, earned);
  }

  function calculateEarn(uint256 stakedAt) internal view returns (uint256) {
    uint256 vaultBalance = IERC20(erc20Address).balanceOf(address(this));
    uint256 totalFunding = vaultBalance + totalClaimed;

    uint256 vaultDuration = vaultEnd - vaultStart;
    uint256 vaultDays = vaultDuration / 1 days;

    uint256 payout = totalFunding / totalSupply / vaultDays;
    uint256 stakeDuration = min(block.timestamp, vaultEnd) - stakedAt;

    return (payout * stakeDuration) / 1 days;
  }

  function earningInfo(address account, uint256[] calldata tokenIds)
    external
    view
    returns (uint256)
  {
    uint256 tokenId;
    uint256 earned = 0;

    for (uint256 i; i != tokenIds.length; i++) {
      tokenId = tokenIds[i];
      Stake memory staked = vault[tokenId];
      require(staked.owner == account, "not an owner");
      uint256 stakedAt = staked.timestamp;
      earned += calculateEarn(stakedAt);
    }
    return earned;
  }

  // get number of tokens staked in account
  function balanceOf(address account) external view returns (uint256) {
    uint256 balance = 0;

    for (uint256 i = 0; i <= totalSupply; i++) {
      if (vault[i].owner == account) {
        balance++;
      }
    }
    return balance;
  }

  // return nft tokens staked of owner
  function tokensOfOwner(address account)
    external
    view
    returns (uint256[] memory ownerTokens)
  {
    uint256[] memory tmp = new uint256[](totalSupply);

    uint256 index = 0;
    for (uint256 tokenId = 0; tokenId <= totalSupply; tokenId++) {
      if (vault[tokenId].owner == account) {
        tmp[index] = vault[tokenId].tokenId;
        index++;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for (uint256 i; i != index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? b : a;
  }

  function onERC721Received(
    address,
    address,
    // address from,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    // require(from == address(0x0), "Cannot send nfts to Vault directly");
    return IERC721Receiver.onERC721Received.selector;
  }

  function withdraw(uint256 amount) external onlyOwner {
    IERC20(erc20Address).transfer(address(this), amount);
  }

  // fallback
  fallback() external payable {}

  // receive eth
  receive() external payable {}
}