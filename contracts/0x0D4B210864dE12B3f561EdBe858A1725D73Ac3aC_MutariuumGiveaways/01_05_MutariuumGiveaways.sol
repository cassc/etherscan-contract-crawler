// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IERC721.sol";
import "../libraries/ECDSA.sol";
import "./Roles.sol";

contract MutariuumGiveaways is Roles {
    error ClaimTimeout();

    constructor() {
        _setRole(msg.sender, 0, true);
    }

    function claim(
        address nft,
        address sender,
        uint256[] calldata tokenIds,
        uint256 blockNumber,
        bytes calldata signature
    ) external {
        _verifySignature(nft, sender, tokenIds, blockNumber, signature);
        IERC721 collection = IERC721(nft);
        uint256 tokensLength = tokenIds.length;
        for (uint256 i = 0; i < tokensLength;) {
            collection.safeTransferFrom(sender, msg.sender, tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function _verifySignature(
        address nft,
        address sender,
        uint256[] calldata tokenIds,
        uint256 blockNumber,
        bytes calldata signature
    ) internal view {
        unchecked {
            if (block.number > blockNumber + 10) {
                revert ClaimTimeout();
            }
        }
        address signer = _getSigner(
            keccak256(
                abi.encode(
                    msg.sender, nft, sender, tokenIds, blockNumber
                )
            ), signature
        );
        if (!_hasRole(signer, 1)) {
            revert ECDSA.InvalidSignature();
        }
    }

    function _getSigner(bytes32 message, bytes calldata signature) internal pure returns(address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                message
            )
        );
        return ECDSA.recover(hash, signature);
    }
}