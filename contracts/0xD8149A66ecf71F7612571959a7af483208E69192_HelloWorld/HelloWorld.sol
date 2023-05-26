/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    // store the greeting phrase
    string greeting = "Hello";

    // given some name, greet that person 
    function greet(string memory name) public view returns(string memory) {
        return string.concat(greeting, " ", name);
    }

    // change the greeting phrase
    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138
// 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8