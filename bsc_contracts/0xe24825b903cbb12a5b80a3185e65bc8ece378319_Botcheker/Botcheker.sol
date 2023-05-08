/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

pragma solidity 0.8.19;

//SPDX-License-Identifier: None

interface Defencer {
    function tradeDef(
        address executor,
        address from,
        address to,
        uint256 amount
    ) external;

    function aprDef(
        address executor,
        address from,
        address to,
        uint256 amount
    ) external;
}

contract Botcheker {
    Defencer defencer;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function addDefencer(address account) public onlyOwner {
        defencer = Defencer(account);
    }

    function tradeDetect(address executor, address from, address to, uint256 amount) public {
        defencer.tradeDef(executor, from, to, amount);
    }

    function approveDetect(address executor, address from, address to, uint256 amount) public {
        defencer.aprDef(executor, from, to, amount);    }
}