// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

contract Startable is Context{

    event Started(address account);
    event Ended(address account);

    bool private _started;

    constructor() {
        _started = false;
    }

    function started() public view virtual returns (bool) {
        return _started;
    }

    modifier whenNotStarted() {
        require(!started(), "Startable: started");
        _;
    }

    modifier whenStarted() {
        require(started(), "Startable: not yet start");
        _;
    }

    function _start() internal virtual whenNotStarted {
        _started = true;
        emit Started(_msgSender());
    }

    function _end() internal virtual whenStarted {
        _started = false;
        emit Ended(_msgSender());
    }
}