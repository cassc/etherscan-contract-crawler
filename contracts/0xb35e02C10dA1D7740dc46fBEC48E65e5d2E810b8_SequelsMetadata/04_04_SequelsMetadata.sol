// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship
// contract by steviep.eth

/*

███████ ███████  ██████  ██    ██ ███████ ██      ███████
██      ██      ██    ██ ██    ██ ██      ██      ██
███████ █████   ██    ██ ██    ██ █████   ██      ███████
     ██ ██      ██ ▄▄ ██ ██    ██ ██      ██           ██
███████ ███████  ██████   ██████  ███████ ███████ ███████
                    ▀▀

███    ███ ███████ ████████  █████  ██████   █████  ████████  █████
████  ████ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██
██ ████ ██ █████      ██    ███████ ██   ██ ███████    ██    ███████
██  ██  ██ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██
██      ██ ███████    ██    ██   ██ ██████  ██   ██    ██    ██   ██

*/

import "./SequelsBase.sol";
import "./Dependencies.sol";

pragma solidity ^0.8.17;

contract SequelsMetadata {
  using Strings for uint256;

  SequelsBase public sequelsBase;
  string public ipfsCid;

  constructor(SequelsBase _sequelsBase) {
    sequelsBase = _sequelsBase;
  }

  function owner() public view returns (address) {
    return sequelsBase.owner();
  }

  function setIpfsCid(string calldata cid) external {
    require(msg.sender == owner(), "Ownable: caller is not the owner");
    ipfsCid = cid;
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return string(abi.encodePacked('ipfs://', ipfsCid, '/', tokenId.toString()));
  }
}
