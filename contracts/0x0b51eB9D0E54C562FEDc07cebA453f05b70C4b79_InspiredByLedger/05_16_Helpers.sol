// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Types } from "./Types.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Helpers {
    function uint2string(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _verify(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (bool) {
        return signer == ECDSA.recover(hash, signature);
    }

    function _hash(
        Types.TokenGatedMintArgs memory args,
        uint256 deadline,
        uint16 seasonId
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        args.tokenId,
                        args.amount,
                        args.tokenGatedId,
                        seasonId,
                        deadline,
                        args.pass,
                        address(this)
                    )
                )
            );
    }

    function readableStablePrice(
        uint256 stableMintPrice
    ) internal pure returns (string memory) {
        uint256 dollars = stableMintPrice / 1000000;
        uint256 cents = (stableMintPrice / 10000) % 100;
        return
            string(
                abi.encodePacked(
                    Helpers.uint2string(dollars),
                    ".",
                    Helpers.uint2string(cents)
                )
            );
    }
}