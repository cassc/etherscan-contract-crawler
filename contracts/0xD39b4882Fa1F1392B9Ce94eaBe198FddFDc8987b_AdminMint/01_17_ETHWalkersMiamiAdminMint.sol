// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./ETHWalkersMiami.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AdminMint is Ownable, Pausable {
    ETHWalkersMiami private ewalk;

    constructor() {
        address EwalksMiamiAddress = 0xD56814B97396c658373A8032C5572957D123a49e;
        ewalk = ETHWalkersMiami(EwalksMiamiAddress);
    }

    function mintReserveETHWalkersMiami(address _to, uint256 _reserveAmount) public onlyOwner whenNotPaused {
        ewalk.controllerMint(_to ,_reserveAmount);
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

}