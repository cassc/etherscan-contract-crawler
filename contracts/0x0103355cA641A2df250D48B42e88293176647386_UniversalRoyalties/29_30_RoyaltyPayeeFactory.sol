// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IRoyaltyFactory.sol";
import "./RoyaltyPayee.sol";

contract RoyaltyPayeeFactory is IRoyaltyFactory {
    address public implementation;
    UniversalRegistrar public registrar;
    using Clones for address;
    event NewRoyaltyPayee(bytes32 node, address indexed contractAddress);

    constructor(address _implementation, UniversalRegistrar _registrar)  {
        implementation = _implementation;
        registrar = _registrar;
    }

    function create(bytes32 node) external override returns (address) {
        address contractAddress = implementation.clone();

        RoyaltyPayee payee = RoyaltyPayee(payable(contractAddress));
        payee.initialize(registrar, node, /* owner share */ 80, /* registry share */ 20);
        emit NewRoyaltyPayee(node, contractAddress);

        return contractAddress;
    }
}