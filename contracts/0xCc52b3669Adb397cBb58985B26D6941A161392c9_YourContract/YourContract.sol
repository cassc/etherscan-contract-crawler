/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract Kudzu {
    function transferFrom(address from, address to, uint256 tokenId) public { }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) { }
}

contract YourContract {

  Kudzu kudzu;

  constructor(address kudzuAddress) {
    kudzu = Kudzu(kudzuAddress);
  }

  function infect(address toAddress) public {
    kudzu.transferFrom(address(this),toAddress,kudzu.tokenOfOwnerByIndex(address(this),0));
  }

  function batch(address[] memory toAddresses) public {
    for (uint i = 0; i < toAddresses.length; i++) {
      infect(toAddresses[i]);
    }
  }

}