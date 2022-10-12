// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IVotesLite } from "../interfaces/IVotesLite.sol";

abstract contract Distributor is IVotesLite {
  using SafeERC20 for IERC20;

  event InitializeDistributor(IERC20 indexed token, uint256 total, uint256 weightBips, string uri);
  event InitializeDistributionRecord(address indexed beneficiary, uint256 amount);
  event Claim(address indexed beneficiary, uint256 amount);

  struct DistributionRecord {
    bool initialized; // has the claim record been initialized
    uint120 total; // total token quantity claimable
    uint120 claimed; // token quantity already claimed
  }

  mapping (address => DistributionRecord) internal records; // track distribution records per user
  IERC20 public immutable token; // the token being claimed 
  uint256 public total; // total tokens allocated for claims
  uint256 public claimed; // tokens already claimed
  string public uri; // ipfs link on distributor info
  uint256 private immutable weightBips; // voting weight in basis points (15000 = 1.5x factor)

  // provide context on the contract name and version
  function NAME() external virtual returns (string memory);
  function VERSION() external virtual returns (uint);

  constructor (
    IERC20 _token,
    uint256 _total,
    uint256 _weightBips,
    string memory _uri
  ) {
    require(address(_token) != address(0), "Distributor: token is address(0)");
    require(_total > 0, "Distributor: total is 0");

    token = _token;
    total = _total;
    weightBips = _weightBips;
    uri = _uri;
    emit InitializeDistributor(token, total, weightBips, uri);
  }

  function _initializeDistributionRecord(address beneficiary, uint256 amount) internal {
    // CALLER MUST VERIFY THE BENEFICIARY AND AMOUNT ARE VALID!

    // Checks
    require(amount <= type(uint120).max, "Distributor: amount > type(uint120).max");
    require(amount > 0, "Distributor: amount == 0");
	  require(!records[beneficiary].initialized, "Distributor: already initialized");

    // Effects
	  records[beneficiary] = DistributionRecord(true, uint120(amount), 0);
    emit InitializeDistributionRecord(beneficiary, amount);
  }

  function _executeClaim(address beneficiary, uint256 _amount) internal {
    // Checks: NONE! THIS FUNCTION DOES NOT CHECK PERMISSIONS: CALLER MUST VERIFY THE CLAIM IS VALID!
    uint120 amount = uint120(_amount);
    require(amount > 0, "Distributor: no more tokens claimable right now");

    // effects
	  records[beneficiary].claimed += amount;
	  claimed += amount;

    // interactions
    token.safeTransfer(beneficiary, amount);
    emit Claim(beneficiary, amount);
  }

  function getVotes(
    address beneficiary
  ) external override view returns (uint256) {
    // Uninitialized claims will not have any votes! (returns 0)

    // The user can vote using tokens that are allocated to them but not yet claimed
    return (records[beneficiary].total - records[beneficiary].claimed) * weightBips / 10000;
  }

  function getVoteWeightBips(address /*beneficiary*/) external view returns (uint256) {
    return weightBips;
  }

  function getDistributionRecord(address beneficiary) external view virtual returns (DistributionRecord memory) {
    return records[beneficiary];
  }

  // Get the fraction of tokens as basis points
  function _getVestedBips(address beneficiary, uint time) public view virtual returns (uint256);

  // get the number of tokens currently claimable by a specific user
  function getClaimableAmount(address beneficiary) public view virtual returns (uint256) {
    require(records[beneficiary].initialized, "Distributor: claim not initialized");

    DistributionRecord memory record = records[beneficiary];

    uint256 claimable = record.total * _getVestedBips(beneficiary, block.timestamp) / 10000;
    return record.claimed >= claimable
      ? 0 // no more tokens to claim
      : claimable - record.claimed; // claim all available tokens
  }
}