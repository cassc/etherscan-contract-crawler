// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IANTHEM is IERC721 {
  function getNestingStarted(uint256 tokenId) external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

contract ANTHEMNestingView is OwnableUpgradeable, UUPSUpgradeable {
  IANTHEM public tokenContract;

  function setTokenContract(address tokenAddress) public onlyOwner {
    tokenContract = IANTHEM(tokenAddress);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function initialize() public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  struct StakingNFT {
    uint256 tokenId;
    uint256 depositTimestamp;
  }

  struct StakingUser {
    address walletAddress;
    uint256 tokenId;
    uint256 depositTimestamp;
  }

  function tokensOfOwner(address owner) public view returns (uint256[] memory) {
    unchecked {
      uint256 tokenIdsIdx;
      uint256 tokenIdsLength = tokenContract.balanceOf(owner);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);
      for (uint256 i = 1; tokenIdsIdx != tokenIdsLength; ++i) {
        if (tokenContract.ownerOf(i) == owner) {
          tokenIds[tokenIdsIdx++] = i;
        }
      }
      return tokenIds;
    }
  }

  function getDepositNFTsByWalletAddress(
    address walletAddress
  ) external view returns (StakingNFT[] memory) {
    uint256[] memory tokenIds = tokensOfOwner(walletAddress);
    StakingNFT[] memory depositInfo = new StakingNFT[](tokenIds.length);

    for (uint256 i = 0; i < tokenIds.length; i++) {
      StakingNFT memory stakingNFT = StakingNFT(
        tokenIds[i],
        tokenContract.getNestingStarted(tokenIds[i])
      );
      depositInfo[i] = stakingNFT;
    }

    return depositInfo;
  }

  function getDepositUsers(
    uint256 startIndex,
    uint256 endIndex
  ) external view returns (StakingUser[] memory) {
    StakingUser[] memory stakingUsers = new StakingUser[](tokenContract.totalSupply());

    uint256 userCount = 0;

    for (uint256 tokenId = startIndex; tokenId <= endIndex; tokenId++) {
      if (tokenContract.getNestingStarted(tokenId) == 0) {
        continue;
      }

      StakingUser memory stakingNFT = StakingUser(
        tokenContract.ownerOf(tokenId),
        tokenId,
        tokenContract.getNestingStarted(tokenId)
      );

      stakingUsers[userCount] = stakingNFT;
      userCount++;
    }

    // 配列の長さを短縮
    StakingUser[] memory trimmedUsers = new StakingUser[](userCount);
    for (uint256 i = 0; i < userCount; i++) {
      trimmedUsers[i] = stakingUsers[i];
    }
    return trimmedUsers;
  }
}