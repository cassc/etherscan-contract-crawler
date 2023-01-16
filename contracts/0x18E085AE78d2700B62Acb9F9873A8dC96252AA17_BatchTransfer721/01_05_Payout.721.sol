// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract BatchTransfer721 is Ownable {
  mapping(address => bool) public actors;

  constructor() {
    actors[msg.sender] = true;
  }

  function addActor(address[] calldata _actors, bool[] calldata _status) public onlyOwner {
    require(_actors.length == _status.length, "Invalid input");
    for (uint256 i = 0; i < _actors.length; i++) {
      actors[_actors[i]] = _status[i];
    }
  }

  function batchTransfer(address _token, address _source, address[] calldata _receivers, uint256[] calldata _tokenIds) public {
    require(actors[msg.sender], "Invalid actor");
    require(_receivers.length == _tokenIds.length, "Invalid input");
    for (uint256 i = 0; i < _receivers.length; i++) {
      IERC721(_token).transferFrom(_source, _receivers[i], _tokenIds[i]);
    }
  }
}