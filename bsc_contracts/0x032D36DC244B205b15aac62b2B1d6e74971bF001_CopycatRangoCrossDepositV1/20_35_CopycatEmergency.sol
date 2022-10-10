// SPDX-License-Identifier: BUSL-1.1-COPYCAT
pragma solidity ^0.8.0;

import "../interfaces/ICopycatEmergencyAllower.sol";

// Emergency protocol adapted from Timelock system
abstract contract CopycatEmergency {
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);

    uint public constant GRACE_PERIOD = 14 days;

    function allowEmergencyCall(ICopycatEmergencyAllower allower, bytes32 txHash) public virtual view returns(bool);

    function executeTransaction(ICopycatEmergencyAllower allower, address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        // require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));

        // We read from global control instead
        require(allowEmergencyCall(allower, txHash), "A");
        // require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(block.timestamp >= eta, "B");
        require(block.timestamp <= eta + GRACE_PERIOD, "C");

        // queuedTransactions[txHash] = false;

        allower.beforeExecute(txHash);

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "D");

        allower.afterExecute(txHash);

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }
}