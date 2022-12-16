// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "lib/safe-contracts/contracts/common/Enum.sol";
import "lib/safe-contracts/contracts/GnosisSafe.sol";

// used to help generate Txs for onchain approvals
/* 
    bytes32 txHash = getSafeTxHash(...);
    safe.approveHash(txHash);
    executeSafeTxFrom(...);
*/

contract SafeTxHelper {
    function getSafeTxHash(
        address to,
        bytes memory data,
        GnosisSafe safe
    ) public view returns (bytes32 txHash) {
        return
            safe.getTransactionHash(
                to,
                0,
                data,
                Enum.Operation.Call,
                // not using the refunder
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                safe.nonce()
            );
    }

    function executeSafeTxFrom(
        address from,
        bytes memory data,
        GnosisSafe safe
    ) public {
        safe.execTransaction(
            address(safe),
            0,
            data,
            Enum.Operation.Call,
            // not using the refunder
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            // (r,s,v) [r - from] [s - unused] [v - 1 flag for onchain approval]
            abi.encode(from, bytes32(0), bytes1(0x01))
        );
    }
}