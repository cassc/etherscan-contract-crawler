// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PvSignedAllowlist {
    using ECDSA for bytes32;

    uint256 private constant UINT256_MAX = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256[] ticketBatches;
    address signer;

    function _verify(
        bytes calldata _signature, 
        uint256 _ticketId, 
        uint256 _amount
    ) internal view {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _ticketId, _amount));

        require(hash.toEthSignedMessageHash().recover(_signature) == signer, "signature invalid");
    }

    function _invalidate(uint256 _ticketId) internal {
        require(_ticketId < ticketBatches.length * 256, "ticket does not exist");

        uint256 batchId = _ticketId / 256;
        uint256 ticketIdInBatch = _ticketId % 256;

        require((ticketBatches[batchId] >> ticketIdInBatch) & uint256(1) != 0, "ticket already used");
        ticketBatches[batchId] = ticketBatches[batchId] & ~(uint256(1) << ticketIdInBatch);       
    }

    function isEligible(uint256 _ticketId) public view returns (bool) {
        require(_ticketId < ticketBatches.length * 256, "ticket does not exist");

        return (ticketBatches[_ticketId / 256] >> _ticketId % 256) & uint256(1) == 1;
    }

    function _setTicketSupply(uint256 supply) internal {
        uint256 batchAmount = (supply / 256) + 1;
        uint256[] memory newBatchArray = new uint256[](batchAmount);

        for (uint256 i; i < batchAmount; i++) {
            newBatchArray[i] = UINT256_MAX;
        }

        ticketBatches = newBatchArray;
    }

    function _setSigner(address _signer) internal {
        signer = _signer;
    }
}