// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../CrunchToken.sol";

contract HasCrunchParent is Ownable {
    event ParentUpdated(address from, address to);

    CrunchToken public crunch;

    constructor(CrunchToken _crunch) {
        crunch = _crunch;

        emit ParentUpdated(address(0), address(crunch));
    }

    modifier onlyCrunchParent() {
        require(
            address(crunch) == _msgSender(),
            "HasCrunchParent: caller is not the crunch token"
        );
        _;
    }

    function setCrunch(CrunchToken _crunch) public onlyOwner {
        require(address(crunch) != address(_crunch), "useless to update to same crunch token");

        emit ParentUpdated(address(crunch), address(_crunch));

        crunch = _crunch;
    }
}