// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Token_Implementation.sol";

contract TokenFactory is Ownable {
    address public logicContract;

    event ProxyCreated(address indexed proxy);

    constructor(address _logicContract) {
        logicContract = _logicContract;
    }

    function createProxy(address owner, string memory name, string memory symbol, uint256 initialSupply) public onlyOwner returns (address) {
        address newToken = Clones.clone(logicContract);
        TokenImplementation(newToken).initialize(owner, name, symbol, initialSupply);
        emit ProxyCreated(newToken);
        return newToken;
    }
}