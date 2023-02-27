// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC20.sol";

contract TimeToken is ERC20, Ownable {
    constructor() public ERC20("Time Token 003", "T003") {
        _mint(msg.sender, 156600000000000000000000);
    }

    function sendAnnualFee(address _address, uint256 _annualFee)
        public
        onlyOwner
    {
        transfer(_address, _annualFee);
    }
}