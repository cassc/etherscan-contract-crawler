// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Admins.sol";

abstract contract Pause is Admins{

    bool public pause = false;

    modifier notPaused(){
        if(_msgSender() != owner()){
            require(pause == false, "Contract paused");
        }
        _;
    }

    function setPause(bool _pause) public onlyOwnerOrAdmins {
        pause = _pause;
    }
}