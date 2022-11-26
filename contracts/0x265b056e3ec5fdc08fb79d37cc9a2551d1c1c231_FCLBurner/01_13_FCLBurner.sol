// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FCLToken} from "./FCLToken.sol";

contract FCLBurner {
  mapping(string => uint256) public amountBurnedById;
  FCLToken public fclTokenContract;

  constructor(address fclTokenAddress) {
    fclTokenContract = FCLToken(fclTokenAddress);
  }

  function burn(string calldata id, uint256 amount) public {
    fclTokenContract.burnFrom(msg.sender, amount);
    amountBurnedById[id] = amount;
  }
}