//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import {IGatewayHandler} from "../interfaces/IGatewayHandler.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GatewayHandler is IGatewayHandler, Ownable {
    mapping(bytes32 => string) public override gateways;

    function setGateway(bytes32 key_, string calldata gateway_)
        external
        override
        onlyOwner
    {
        gateways[key_] = gateway_;
    }
}