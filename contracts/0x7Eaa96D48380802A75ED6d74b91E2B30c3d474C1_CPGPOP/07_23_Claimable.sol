pragma solidity ^0.8.13;

import "./EIP712Common.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error ClaimingNotActive();

abstract contract Claimable is Ownable, EIP712Common{

  mapping(address => uint256) private claimCounts;

  bool public claimingIsActive = false;

  function flipClaimState() external onlyOwner {
    claimingIsActive = !claimingIsActive;
  }

  function tokensClaimed(address minter) public view returns (uint256) {
    return claimCounts[minter];
  }

  function checkClaimlist(uint256 count, bytes calldata signature) public view requiresClaim(signature, count) returns (bool) {
    return true;
  }

  function hasUnclaimedTokens(address minter) public view returns (bool) {
    return claimCounts[minter] == 0;
  }

  function updateClaimCount(address minter, uint256 count) internal {
    claimCounts[minter] += count;
  }

  modifier requireActiveClaiming {
    if(!claimingIsActive) revert ClaimingNotActive();
    _;
  }
}