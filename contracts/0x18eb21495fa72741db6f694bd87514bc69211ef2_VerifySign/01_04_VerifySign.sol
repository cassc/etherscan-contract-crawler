// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ISeadrop {
    function getSigner(address nftContract) external view returns (address);
}

contract VerifySign {
    using ECDSA for bytes32;

    function hashTransaction(
        address seadrop,
        address token,
        address nftRecipient,
        uint8 stage
    ) public pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(seadrop, token, nftRecipient, stage))
            )
        );
        return hash;
    }

    function checkWhitelistAddress(
        bytes memory signature,
        address seadropAddress,
        address token,
        address nftRecipient,
        uint8 stage
    ) public view returns (bool) {
        bytes32 msgHash = hashTransaction(
            seadropAddress,
            token,
            nftRecipient,
            stage
        );
        if (
            msgHash.recover(signature) !=
            ISeadrop(seadropAddress).getSigner(token)
        ) {
            return false;
        } else {
            return true;
        }
    }
}