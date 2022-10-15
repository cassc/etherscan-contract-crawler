// SPDX-License-Identifier: MIT

/*
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ITokenGate.sol";

contract AssetTokenGate is Ownable, ITokenGate {
  IERC721[] whitelist;

  function setWhitelist(IERC721[] memory _whitelist) external onlyOwner {
    whitelist = _whitelist;
  }

  function balanceOf(address _wallet) external view override returns(uint balance) {
    for (uint i=0; i<whitelist.length; i++) {
      balance += whitelist[i].balanceOf(_wallet);
    }
  }
}