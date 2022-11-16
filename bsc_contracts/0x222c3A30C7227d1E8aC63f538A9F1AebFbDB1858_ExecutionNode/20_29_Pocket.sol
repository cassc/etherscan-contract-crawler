// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

// the pocket is a contract that is to be created conterfactually on the dst chain in the scenario where
// there is a dst swap. the main problem the pocket tries to solve is to gain the ability to know when and
// by how much the bridged tokens are received.
// when chainhop backend builds a cross-chain swap, it calculates a swap id (see _computeSwapId in
// ExecutionNode) and the id is used as the salt in generating a pocket address on the dst chain.
// this address is then assigned as the receiver of the bridge out tokens on the dst chain to temporarily
// hold the funds until the actual pocket contract is deployed at the exact address during the message execution.
contract Pocket {
    function claim(address _token, uint256 _amt) external {
        address sender = msg.sender;
        _token.call(abi.encodeWithSelector(0xa9059cbb, sender, _amt));
        assembly {
            // selfdestruct sends all native balance to sender
            selfdestruct(sender)
        }
    }
}