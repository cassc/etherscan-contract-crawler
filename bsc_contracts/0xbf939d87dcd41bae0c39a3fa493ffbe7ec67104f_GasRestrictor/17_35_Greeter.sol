//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./OwnableUpgradeable.sol";

contract Greeter is OwnableUpgradeable {
mapping(address=> string) public greetings;
    constructor(string memory _greeting, address trustedForwarded) {
        console.log("Deploying a Greeter with greeting:", _greeting);
      __Ownable_init(trustedForwarded);
    }

    function greet() public view returns (string memory) {
        return greetings[_msgSender()];
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", _greeting);
        greetings[_msgSender()] = _greeting;
    }
}