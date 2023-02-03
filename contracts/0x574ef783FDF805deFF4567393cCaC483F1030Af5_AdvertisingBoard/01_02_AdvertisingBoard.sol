// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IOpsProxyFactory} from "./IOpsProxyFactory.sol";

contract AdvertisingBoard {
    IOpsProxyFactory public immutable opsProxyFactory;
    mapping(address => string) public messages;

    constructor(IOpsProxyFactory _opsProxyFactory) {
        opsProxyFactory = _opsProxyFactory;
    }

    function postMessage(string calldata _message) external {
        messages[msg.sender] = _message;
    }

    function viewMessage(address _eoa) external view returns (string memory) {
        (address dedicatedMsgSender, ) = opsProxyFactory.getProxyOf(_eoa);

        return messages[dedicatedMsgSender];
    }
}