// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IBHeroDesign.sol";

interface IBHeroToken {
  function design() external view returns (IBHeroDesign);

  function getTotalHeroByUser(address user) external view returns (uint256);

  function createTokenRequest(
    address to,
    uint256 count,
    uint256 rarity,
    uint256 targetBlock,
    uint256 details
  ) external;
}

contract BHeroClaim is AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

  IBHeroToken public heroToken;
  mapping(address => uint256[]) public requestDetails;

  function initialize(IBHeroToken heroToken_) public initializer {
    __AccessControl_init();
    __Pausable_init();
    __UUPSUpgradeable_init();

    heroToken = heroToken_;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(PAUSER_ROLE, msg.sender);
    _setupRole(UPGRADER_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
  }

  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  function supportsInterface(bytes4 interfaceId) public view override(AccessControlUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function addClaimRequests(
    address to,
    uint256 count,
    uint256 rarity,
    uint256 category,
    uint256 isHeroS,
    uint256[] calldata dropRates,
    uint256 skin
  ) external onlyRole(MINTER_ROLE) {
    require(rarity <= 6, "Invalid rarity");
    uint256 details;
    details |= count;
    details |= rarity << 10;
    details |= category << 15;
    details |= isHeroS << 20;
    details |= dropRates.length << 25;
    uint256 totalDropRate;
    for (uint256 i = 0; i < dropRates.length; ++i) {
      details |= dropRates[i] << (30 + i * 15);
      totalDropRate += dropRates[i];
    }
    details |= skin << 120;
    require(totalDropRate > 0, "Drop rate must be positive");
    require(dropRates.length == 6, "Invalid drop rate size");
    requestDetails[to].push(details);
  }

  function getClaimableTokens(address to) external view returns (uint256) {
    uint256 result;
    for (uint256 i = 0; i < requestDetails[to].length; ++i) {
      uint256 count = requestDetails[to][i] & (2**10 - 1);
      result += count;
    }
    return result;
  }

  function claim() external {
    address to = msg.sender;
    uint256 size = heroToken.getTotalHeroByUser(to);
    uint256 limit = heroToken.design().getTokenLimit();
    require(size < limit, "User limit reached");

    for (uint256 i = 0; i < requestDetails[to].length; ++i) {
      uint256 details = requestDetails[to][i];
      uint256 count = details & (2**10 - 1);
      uint256 rarity = (details >> 10) & (2**5 - 1);

      uint256 targetBlock = block.number + 5;

      // category: 5 bits.
      // isHeroS: 5 bits.
      // dropLength: 5 bits.
      // max 6 drops: 15 * 6 = 90 bits.
      // skin: 5 bits.
      uint256 moreDetails = (details >> 15) & ((uint256(1) << 110) - 1);

      uint256 tokenRequestDetails = targetBlock | (moreDetails << 30);
      heroToken.createTokenRequest(to, count, rarity, targetBlock, tokenRequestDetails);
    }
    delete requestDetails[to];
  }

  function addHeroesEvent(address[] calldata users, uint256[] calldata skins) public onlyRole(MINTER_ROLE) {
    uint256[] memory dropRates = heroToken.design().getDropRateHeroS();
    require(users.length == skins.length, "Wrong length");
    for (uint256 i = 0; i < users.length; ++i) {
      this.addClaimRequests(users[i], 1, 0, 0, 1, dropRates, skins[i]);
    }
  }
}