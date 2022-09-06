// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Portal.sol";
import {Clones} from "./Libraries/Clones.sol";

contract PortalFactory {
    using Clones for address;

    address public immutable portalImplementation;

    event Deployed(Portal instance);

    constructor(address portal_) {
        portalImplementation = portal_;
    }

    function deploy(bytes32[] calldata commands, bytes[] calldata state) public payable returns (Portal instance) {
        instance = Portal(payable(portalImplementation.cloneDeterministic(msg.sender)));
        instance.initialize{value: msg.value}(msg.sender, commands, state);

        emit Deployed(instance);
    }

    function getAddress() public view returns (address payable) {
        return payable(portalImplementation.predictDeterministicAddress(msg.sender, address(this)));
    }
}