// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./Delegated.sol";
import "./ERC721Batch.sol";
import "./IERC20Proxy.sol";

abstract contract ERC721Staked is Delegated, ERC721Batch {
  using Strings for uint256;

  struct StakeConfig {
    address coinContract;
    uint256 stakePeriod;
    uint256 stakeReward;
  }

  StakeConfig public stakeConfig;

  mapping(uint8 => uint256) public rarityMultiplier;

  function setRarityMultiplier(uint8 _rarity, uint256 _multiplier)
    external
    onlyDelegates
  {
    rarityMultiplier[_rarity] = _multiplier;
  }

  function claimTokens(uint256[] calldata tokenIds, bool restake) external {
    uint256 coinQuantity;
    uint32 time = uint32(block.timestamp);
    for (uint256 i; i < tokenIds.length; ++i) {
      require(_exists(tokenIds[i]), "claim for nonexistent token");

      Token storage token = tokens[tokenIds[i]];
      require(token.owner == msg.sender, "caller is not owner");
      require(
        token.stakeDate > 1,
        string(
          abi.encodePacked("token ", tokenIds[i].toString(), " is not staked")
        )
      );
      uint256 baseQuantity = ((time - token.stakeDate) *
        stakeConfig.stakeReward) / stakeConfig.stakePeriod;

      coinQuantity += baseQuantity * rarityMultiplier[token.rarity];

      if (restake) token.stakeDate = time;
      else token.stakeDate = 1;
    }

    IERC20Proxy(stakeConfig.coinContract).mintTo(msg.sender, coinQuantity);
  }

  function stakeTokens(uint256[] calldata tokenIds) external {
    for (uint256 i; i < tokenIds.length; ++i) {
      require(_exists(tokenIds[i]), "stake for nonexistent token");

      Token storage token = tokens[tokenIds[i]];
      require(token.owner == msg.sender, "caller is not owner");
      require(
        token.stakeDate < 2,
        string(
          abi.encodePacked(
            "token ",
            tokenIds[i].toString(),
            " is already staked"
          )
        )
      );
      tokens[tokenIds[i]].stakeDate = uint32(block.timestamp);
    }
  }

  //delegated
  function setStakeConfig(StakeConfig calldata stakeConfig_)
    external
    onlyDelegates
  {
    stakeConfig = stakeConfig_;
  }

  //internal
  function _isStaked(uint256 tokenId) internal view virtual returns (bool) {
    return tokens[tokenId].stakeDate > 1;
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    require(!_isStaked(tokenId), "token is staked");
    super._transfer(from, to, tokenId);
  }
}