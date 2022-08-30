//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface ISSA {
  function giftAnAgent(address _to, uint _count) external;
  function transferOwnership(address newOwner) external;
}

contract SSAirdropper is Ownable {

  address constant SSA_CONTRACT = 0x007029dfb0Bc69dF0303E48D3e458eFa3Db6d98f;

  function airdrop(address[] calldata _addresses, uint[] calldata _counts)
    external
    onlyOwner
  {
    ISSA ssa = ISSA(SSA_CONTRACT);
    for(uint i; i < _addresses.length;) {
      ssa.giftAnAgent(_addresses[i], _counts[i]);
      unchecked { ++i; }
    }
  }

  function transferSSAOwnership(address _to)
    external
    onlyOwner
  {
    ISSA ssa = ISSA(SSA_CONTRACT);
    ssa.transferOwnership(_to);
  }
}