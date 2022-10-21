// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { SendUtils } from "./SendUtils.sol";

abstract contract ArbitraryCall is Ownable {
    using Address for address payable;

    event ArbitraryCallReturn(bytes returndata);

    /// Performs an external call to the specified address with the specified arguments.
    /// This function is meant to allow the owner of the contract to reap benefits of being
    /// a frequent customer of OpenSea. For example, to collect an airdrop.
    ///
    /// @dev This function would be a big security liability in a contract holding significant amounts
    /// of funds or being whilelisted to perform privileged actions in other contracts. Currently
    /// this is not the case and it's very important to ensure that it stays that way.
    /// This function gives the owner the ability to freely impersonate the contract. If the owner contract
    /// gets compromised, the attacker will have the same power.
    function arbitraryCall(address payable targetContract, bytes calldata encodedArguments) public payable onlyOwner returns (bytes memory) {
        // NOTE: If the contract has no receive() function and the target contract tries to send ether
        // back to msg.sender, the transaction will fail.
        bytes memory returndata = targetContract.functionCallWithValue(encodedArguments, msg.value);

        SendUtils._returnAllEth();
        emit ArbitraryCallReturn(returndata);
        return returndata;
    }
}