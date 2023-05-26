// SPDX-License-Identifier: MIT
// BuildingIdeas.io (Rewardable.sol)

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IEDOToken.sol";

abstract contract Rewardable is Ownable {

  IEDOToken public yieldToken;

  function setYieldToken(address _yield) external onlyOwner {
		yieldToken = IEDOToken(_yield);
	}
}