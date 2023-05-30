// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Stakeholders.sol";
import "./Community.sol";
import "./FurLib.sol";

/// @title Governance
/// @author LFG Gaming LLC
/// @notice Meta-tracker for Furballs; looks at the ecosystem (metadata, wallet counts, etc.)
/// @dev Shares is an ERC20; stakeholders is a payable
contract Governance is Stakeholders {
  /// @notice Where transaction fees are deposited
  address payable public treasury;

  /// @notice How much is the transaction fee, in basis points?
  uint16 public transactionFee = 250;

  /// @notice Used in contractURI for Furballs itself.
  string public metaName = "Furballs.com (Official)";

  /// @notice Used in contractURI for Furballs itself.
  string public metaDescription =
    "Furballs are entirely on-chain, with a full interactive gameplay experience at Furballs.com. "
    "There are 88 billion+ possible furball combinations in the first edition, each with their own special abilities"
    "... but only thousands minted per edition. Each edition has new artwork, game modes, and surprises.";

  // Tracks the MAX which are ever owned by a given address.
  mapping(address => FurLib.Account) private _account;

  // List of all addresses which have ever owned a furball.
  address[] public accounts;

  Community public community;

  constructor(address furballsAddress) Stakeholders(furballsAddress) {
    treasury = payable(this);
  }

  /// @notice Generic form of contractURI for on-chain packing.
  /// @dev Proxied from Furballs, but not called contractURI so as to not imply this ERC20 is tradeable.
  function metaURI() public view returns(string memory) {
    return string(abi.encodePacked("data:application/json;base64,", FurLib.encode(abi.encodePacked(
      '{"name": "', metaName,'", "description": "', metaDescription,'"',
      ', "external_link": "https://furballs.com"',
      ', "image": "https://furballs.com/images/pfp.png"',
      ', "seller_fee_basis_points": ', FurLib.uint2str(transactionFee),
      ', "fee_recipient": "0x', FurLib.bytesHex(abi.encodePacked(treasury)), '"}'
    ))));
  }

  /// @notice total count of accounts
  function numAccounts() external view returns(uint256) {
    return accounts.length;
  }

  /// @notice Update metadata for main contractURI
  function setMeta(string memory nameVal, string memory descVal) external gameAdmin {
    metaName = nameVal;
    metaDescription = descVal;
  }

  /// @notice The transaction fee can be adjusted
  function setTransactionFee(uint16 basisPoints) external gameAdmin {
    transactionFee = basisPoints;
  }

  /// @notice The treasury can be changed in only rare circumstances.
  function setTreasury(address treasuryAddress) external onlyOwner {
    treasury = payable(treasuryAddress);
  }

  /// @notice The treasury can be changed in only rare circumstances.
  function setCommunity(address communityAddress) external onlyOwner {
    community = Community(communityAddress);
  }

  /// @notice public accessor updates permissions
  function getAccount(address addr) external view returns (FurLib.Account memory) {
    FurLib.Account memory acc = _account[addr];
    acc.permissions = _userPermissions(addr);
    return acc;
  }

  /// @notice Public function allowing manual update of standings
  function updateStandings(address[] memory addrs) public {
    for (uint32 i=0; i<addrs.length; i++) {
      _updateStanding(addrs[i]);
    }
  }

  /// @notice Moderators may assign reputation to accounts
  function setReputation(address addr, uint16 rep) external gameModerators {
    _account[addr].reputation = rep;
  }

  /// @notice Tracks the max level an account has *obtained*
  function updateMaxLevel(address addr, uint16 level) external gameAdmin {
    if (_account[addr].maxLevel >= level) return;
    _account[addr].maxLevel = level;
    _updateStanding(addr);
  }

  /// @notice Recompute max stats for the account.
  function updateAccount(address addr, uint256 numFurballs) external gameAdmin {
    FurLib.Account memory acc = _account[addr];

    // Recompute account permissions for internal rewards
    uint8 permissions = _userPermissions(addr);
    if (permissions != acc.permissions) _account[addr].permissions = permissions;

    // New account created?
    if (acc.created == 0) _account[addr].created = uint64(block.timestamp);
    if (acc.numFurballs != numFurballs) _account[addr].numFurballs = uint32(numFurballs);

    // New max furballs?
    if (numFurballs > acc.maxFurballs) {
      if (acc.maxFurballs == 0) accounts.push(addr);
      _account[addr].maxFurballs = uint32(numFurballs);
    }
    _updateStanding(addr);
  }

  /// @notice Re-computes the account's standing
  function _updateStanding(address addr) internal {
    uint256 standing = 0;
    FurLib.Account memory acc = _account[addr];

    if (address(community) != address(0)) {
      // If community is patched in later...
      standing = community.update(acc, addr);
    } else {
      // Default computation of standing
      uint32 num = acc.numFurballs;
      if (num > 0) {
        standing = num * 10 + acc.maxLevel + acc.reputation;
      }
    }

    _account[addr].standing = uint16(standing);
  }
}