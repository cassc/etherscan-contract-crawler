// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import { IDistributor, DistributionRecord } from '../../interfaces/IDistributor.sol';

abstract contract Distributor is IDistributor, ReentrancyGuard {
  using SafeERC20 for IERC20;

  mapping(address => DistributionRecord) internal records; // track distribution records per user
  IERC20 public token; // the token being claimed
  uint256 public total; // total tokens allocated for claims
  uint256 public claimed; // tokens already claimed
  string public uri; // ipfs link on distributor info
  uint256 immutable fractionDenominator; // denominator for vesting fraction (e.g. if vested fraction is 100 and fractionDenominator is 10000, 1% of tokens have vested)

  // provide context on the contract name and version
  function NAME() external view virtual returns (string memory);

  function VERSION() external view virtual returns (uint256);

  constructor(
    IERC20 _token,
    uint256 _total,
    string memory _uri,
    uint256 _fractionDenominator
  ) {
    require(address(_token) != address(0), 'Distributor: token is address(0)');
    require(_total > 0, 'Distributor: total is 0');

    token = _token;
    total = _total;
    uri = _uri;
    fractionDenominator = _fractionDenominator;
    emit InitializeDistributor(token, total, uri, fractionDenominator);
  }

  function _initializeDistributionRecord(address beneficiary, uint256 _totalAmount) internal virtual {
    // CALLER MUST VERIFY THE BENEFICIARY AND TOTAL ARE VALID!
		uint120 totalAmount = uint120(_totalAmount);

    // Checks
    require(totalAmount <= type(uint120).max, 'Distributor: totalAmount > type(uint120).max');

    // Effects - note that the existing claimed quantity is re-used during re-initialization
    records[beneficiary] = DistributionRecord(true, totalAmount, records[beneficiary].claimed);
    emit InitializeDistributionRecord(beneficiary, totalAmount);
  }

  function _executeClaim(address beneficiary, uint256 _totalAmount) internal virtual returns (uint256) {
    // Checks: NONE! THIS FUNCTION DOES NOT CHECK PERMISSIONS: CALLER MUST VERIFY THE CLAIM IS VALID!
		uint120 totalAmount = uint120(_totalAmount);
	
    // effects
		if (records[beneficiary].total != totalAmount) {
			// re-initialize if the total has been updated
			_initializeDistributionRecord(beneficiary, totalAmount);
		}

		uint120 claimableAmount = uint120(getClaimableAmount(beneficiary));
    require(claimableAmount > 0, 'Distributor: no more tokens claimable right now');

    records[beneficiary].claimed += claimableAmount;
    claimed += claimableAmount;

    // interactions
    token.safeTransfer(beneficiary, claimableAmount);
    emit Claim(beneficiary, claimableAmount);

		return claimableAmount;
  }

  function getDistributionRecord(address beneficiary)
    external
    view
    virtual
    returns (DistributionRecord memory)
  {
    return records[beneficiary];
  }

  // Get tokens vested as fraction of fractionDenominator
  function getVestedFraction(address beneficiary, uint256 time)
    public
    view
    virtual
    returns (uint256);

  function getFractionDenominator() public view returns (uint256) {
    return fractionDenominator;
  }

  // get the number of tokens currently claimable by a specific use
  function getClaimableAmount(address beneficiary) public view virtual returns (uint256) {
    require(records[beneficiary].initialized, 'Distributor: claim not initialized');

    DistributionRecord memory record = records[beneficiary];

    uint256 claimable = (record.total * getVestedFraction(beneficiary, block.timestamp)) /
      fractionDenominator;
    return
      record.claimed >= claimable
        ? 0 // no more tokens to claim
        : claimable - record.claimed; // claim all available tokens
  }
}