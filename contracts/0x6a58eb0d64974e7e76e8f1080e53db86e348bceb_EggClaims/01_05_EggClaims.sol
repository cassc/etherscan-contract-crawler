// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract EggClaims is Context, AccessControl {
    event EggClaim(address indexed from);
    event PickWinners(uint8 indexed idoType);
    event PickEggs();

    // Mapping from address to bool, if egg was already claimed
    mapping(address => bool) public registeredAddresses;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function register() public {
        require(!registeredAddresses[_msgSender()], "Already registered");
        registeredAddresses[_msgSender()] = true;
        emit EggClaim(_msgSender());
    }

    function pickWinners(uint8 idoType) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Must have admin role to initiate pickwinners flow"
        );
        require(
            idoType == 1 || idoType == 2,
            "Must either be 1 (public) or 2 (pols)"
        );
        if (idoType == 1) {
            emit PickEggs();
        }
        emit PickWinners(idoType);
    }
}