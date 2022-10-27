// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./INST.sol";

abstract contract Rewardable is Ownable {

  INST public yieldToken;

  function setYieldToken(address _yield) external onlyOwner {
		yieldToken = INST(_yield);
	}
}