// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error AddressNotAllowed();
error CannotMintMoreThan(uint256 amount);
error NeedToSendMoreETH();
error QuantityWouldExceedMaxSupply();
error MintHasNotStarted();
error MintHasEnded();
error PartialRefundFailed();

library MintGate {

    function allowlist(address buyer, bytes32[] memory proof, bytes32 root) internal pure {
        if (!isAllowlisted(buyer, proof, root)) {
            revert AddressNotAllowed();
        }
    }

    function isAllowlisted(address buyer, bytes32[] memory proof, bytes32 root) internal pure returns (bool) {
        // Doesn't use an allowlist
        if (root == 0) {
            return true;
        }

        // Proof was not provided or merkle verify failed
        if (proof.length == 0 || !MerkleProof.verify(proof, root, keccak256(abi.encodePacked(buyer)))) {
            return false;
        }

        return true;
    }

    function maxMint(uint256 max, uint256 minted, uint256 quantity) internal pure {
        unchecked {
            if (max > 0 && (minted + quantity) > max) {
                revert CannotMintMoreThan({ amount: max });
            }
        }
    }

    function open(uint256 end, uint256 start) internal view {
        if (block.timestamp < start) {
            revert MintHasNotStarted();
        }

        if (end != 0 && block.timestamp > end) {
            revert MintHasEnded();
        }
    }

    function price(address buyer, uint256 cost, uint256 quantity, uint256 received) internal {
        unchecked {
            uint256 total = cost * quantity;

            if (received < total) {
                revert NeedToSendMoreETH();
            }

            // Refund remaining value
            if (received > total) {
                (bool success, ) = payable(buyer).call{value: (received - total)}('');

                if (!success) {
                    revert PartialRefundFailed();
                }
            }
        }
    }

    function supply(uint256 available, uint256 quantity) internal pure {
        if (quantity > available) {
            revert QuantityWouldExceedMaxSupply();
        }
    }

    function supply(uint256 available, uint256 max, uint256 minted, uint256 quantity) internal pure {
        maxMint(max, minted, quantity);
        supply(available, quantity);
    }
}