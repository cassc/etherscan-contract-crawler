// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MetToken.sol";


contract MetReverseSplit is Ownable {

  MetToken token;

  constructor(MetToken _token) {
    token = _token;
  }

  function reverseSplit(address[] calldata addresses) public onlyOwner {

    for (uint256 i; i<addresses.length; i++) {

      token.burnFrom(
        addresses[i],
        token.balanceOf(addresses[i]) * 99 / 100
      );

    }

  }

}