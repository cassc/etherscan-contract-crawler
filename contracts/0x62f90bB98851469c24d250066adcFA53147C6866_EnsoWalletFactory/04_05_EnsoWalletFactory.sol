// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./EnsoWallet.sol";
import {Clones} from "./Libraries/Clones.sol";

contract EnsoWalletFactory {
    using Clones for address;

    address public immutable ensoWallet;

    event Deployed(EnsoWallet instance);

    constructor(address EnsoWallet_) {
        ensoWallet = EnsoWallet_;
    }

    function deploy(bytes32[] calldata commands, bytes[] calldata state) public payable returns (EnsoWallet instance) {
        instance = EnsoWallet(payable(ensoWallet.cloneDeterministic(msg.sender)));
        instance.initialize{value: msg.value}(msg.sender, commands, state);

        emit Deployed(instance);
    }

    function getAddress() public view returns (address payable) {
        return payable(ensoWallet.predictDeterministicAddress(msg.sender, address(this)));
    }
}