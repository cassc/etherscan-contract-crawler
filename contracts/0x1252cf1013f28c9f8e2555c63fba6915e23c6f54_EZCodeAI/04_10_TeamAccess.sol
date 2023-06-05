// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract TeamAccess is Context {
    address private _team;

    event TeamAddressChanged(address indexed previousTeamAddress, address indexed newTeamAddress);

    constructor() {
        _changeTeamAddress(_msgSender());
    }

    modifier isTeamAddress() {
        _checkTeamAddress();
        _;
    }

    function team() public view virtual returns (address) {
        return _team;
    }

    function _checkTeamAddress() internal view virtual {
        require(team() == _msgSender(), "Caller is not the team address");
    }

    function changeTeamAddress(address newTeamAddress) public virtual isTeamAddress {
        require(newTeamAddress != address(0), "New team address is the zero address");
        _changeTeamAddress(newTeamAddress);
    }

    function _changeTeamAddress(address newTeamAddress) internal virtual {
        address oldTeamAddress = _team;
        _team = newTeamAddress;
        emit TeamAddressChanged(oldTeamAddress, newTeamAddress);
    }
}