// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../../utils/Types.sol";
import "../../utils/BlockchainUtils.sol";

struct PlatformFees {
    address assetAddress;
    uint256 tokenId;
    uint8 buyerFeePermille;
    uint8 sellerFeePermille;
    Signature signature;
}

library PlatformFeesFunctions {
    function checkValidPlatformFees(PlatformFees calldata platformFees, address owner) internal pure {
        bytes32 hash =
            keccak256(
                abi.encodePacked(
                    BlockchainUtils.getChainID(),
                    platformFees.assetAddress,
                    platformFees.tokenId,
                    platformFees.buyerFeePermille,
                    platformFees.sellerFeePermille
                )
            );
        require(owner == BlockchainUtils.getSigner(hash, platformFees.signature), "fees sign verification failed");
    }
}