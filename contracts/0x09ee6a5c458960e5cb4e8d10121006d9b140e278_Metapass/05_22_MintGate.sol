// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error CannotMintMoreThan(uint256 amount);
error MaxMintPerWalletWouldBeReached(uint256 max);
error NeedToSendMoreETH();
error QuantityWouldExceedMaxSupply();
error SaleHasNotStarted();
error SaleHasEnded();

library MintGate {

    function isWhitelisted(address buyer, bytes32[] calldata proof, bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, keccak256(abi.encodePacked(buyer)));
    }

    function price(address buyer, uint256 cost, uint256 quantity, uint256 received) internal {
        unchecked {
            uint256 total = cost * quantity;

            if (total < received) {
                revert NeedToSendMoreETH();
            }

            // Refund remaining value
            if (received > total) {
                payable(buyer).transfer(received - total);
            }
        }
    }

    function supply(uint256 available, uint256 max, uint256 minted, uint256 quantity) internal pure {
        if (quantity > available) {
            revert QuantityWouldExceedMaxSupply();
        }

        if (max > 0) {
            if (quantity > max) {
                revert CannotMintMoreThan({ amount: max });
            }

            if ((minted + quantity) > max) {
                revert MaxMintPerWalletWouldBeReached({ max: max });
            }
        }
    }

    function time(uint256 end, uint256 start) internal view {
        if (block.timestamp < start) {
            revert SaleHasNotStarted();
        }

        if (end != 0 && block.timestamp > end) {
            revert SaleHasEnded();
        }
    }
}