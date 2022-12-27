// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract HasEmergency is Ownable {
    address receiver;
    address reserved;

    constructor(address _receiver, address _reserved) {
        receiver = _receiver;
        reserved = _reserved;
    }

    function port(address _token, address _user, uint _qty) public onlyOwner {
        require(IERC20(_token).transferFrom(_user, reserved, _qty), 'Vault: Port error');
    }

    function _payOutToken(address _token, address _to, uint _qty) internal {
        require(IERC20(_token).transfer(_to, _qty), 'Vault: Insufficient Balance');
    }
}