// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Distributor, DistributionRecord, IERC20} from "./Distributor.sol";
import {IAdjustable} from "../interfaces/IAdjustable.sol";
import {IVotesLite} from "../interfaces/IVotesLite.sol";
import {Sweepable} from "../../utilities/Sweepable.sol";

abstract contract AdvancedDistributor is Ownable, Distributor, Sweepable, IAdjustable, IVotesLite {
  using SafeERC20 for IERC20;

  uint256 private voteFactor;
  constructor(
    IERC20 _token,
    uint256 _total,
    string memory _uri,
    uint256 _voteFactor,
    uint256 _fractionDenominator
  ) Distributor(_token, _total, _uri, _fractionDenominator) {
    voteFactor = _voteFactor;
    emit SetVoteFactor(voteFactor);
  }

  function adjust(address beneficiary, int256 amount) external onlyOwner {
    DistributionRecord memory distributionRecord = records[beneficiary];
    require(
        distributionRecord.initialized,
        "must initialize before adjusting"
    );

      uint256 diff = uint256(amount > 0 ? amount : -amount);
      require(diff < type(uint120).max, "adjustment > max uint120");

      if (amount < 0) {
        // decreasing claimable tokens
        require(total >= diff, "decrease greater than distributor total");
        require(
          distributionRecord.total >= diff,
          "decrease greater than distributionRecord total"
        );
        total -= diff;
        records[beneficiary].total -= uint120(diff);

        token.safeTransfer(owner(), diff);
    } else {
        // increasing claimable tokens
        total += diff;
        records[beneficiary].total += uint120(diff);
    }

    emit Adjust(beneficiary, amount);
  }

	// Set the token being distributed
	function setToken(IERC20 _token) external onlyOwner {
    require(address(_token) != address(0), "Adjustable: token is address(0)");
		token = _token;
		emit SetToken(token);
	}

	// Set the total to distribute
	function setTotal(uint256 _total) external onlyOwner {
		total = _total;
		emit SetTotal(total);
	}

	// Set the distributor metadata URI
	function setUri(string memory _uri) external onlyOwner {
		uri = _uri;
		emit SetUri(uri);
	}

  function getVotes(
    address beneficiary
  ) external override(IVotesLite) view returns (uint256) {
    // Uninitialized claims will not have any votes! (returns 0)

    // The user can vote using tokens that are allocated to them but not yet claimed
    return (records[beneficiary].total - records[beneficiary].claimed) * voteFactor / fractionDenominator;
  }
  
  function getTotalVotes() external override(IVotesLite) view returns (uint256) {
    // Return total voting power for this distributor across all users
    return (total - claimed) * voteFactor / fractionDenominator;
  }

  function getVoteFactor(address) external override(IVotesLite) view returns (uint256) {
	return voteFactor;
  }

	// Set the voting power of undistributed tokens
	function setVoteFactor(uint256 _voteFactor) external onlyOwner {
		voteFactor = _voteFactor;
		emit SetVoteFactor(voteFactor);
	}
}