// SPDX-License-Identifier: Apache-2.0
/// @dev Note, we want to use the 0.7.4 version to align with previous deployment.
pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

/// @dev Used to simulate the Fuel V1.0 control multisig.
contract Multisig {
    /// @dev https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol#L189
    function submitTransaction(address payable destination, uint value, bytes memory data)
        external
        returns (uint transactionId)
    {
        (bool status,) = destination.call{ value: value }(data);
        require(status, "submit-status");
        return 0;
    }
}