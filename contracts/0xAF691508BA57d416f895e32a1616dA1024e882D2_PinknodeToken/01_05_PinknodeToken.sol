// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PinknodeToken is ERC20("Pinknode Token", "PNODE") {

    constructor(address _address, uint256 _amount) {
    	_mint(_address, _amount);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }
}