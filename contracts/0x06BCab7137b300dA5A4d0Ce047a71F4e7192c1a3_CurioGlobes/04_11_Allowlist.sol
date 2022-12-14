// SPDX-License-Identifier: AGPL-3.0
// ©2022 Ponderware Ltd

pragma solidity ^0.8.17;

/*
 * @title Curio Snow Globes Allowlist
 * @author Ponderware Ltd
 * @dev Allowlist using claims of signed addresses
 */
contract Allowlist {

    uint256 public availableClaims = 4976;

    bool public claimingOpen = true;

    bytes32 constant Mask =  0x0000000000000000000000000000000000000000000000000000000000000001;

    bytes32[20] internal Unclaimed;
    address claimSigner;

    constructor (address claimSignerAddress) {
        for (uint i = 0; i < 20; i++) {
            Unclaimed[i] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        claimSigner = claimSignerAddress;
    }

    function _updateClaimSigner (address claimSignerAddress) internal {
        claimSigner = claimSignerAddress;
    }

    function _permanentlyCloseClaiming () internal {
        claimingOpen = false;
    }

    function clearClaimBit(uint16 index) private {
        uint16 wordIndex = index / 256;
        uint16 bitIndex = index % 256;
        bytes32 mask = ~(Mask << (255 - bitIndex));
        Unclaimed[wordIndex] &= mask;
    }

    function isStillAvailable(uint256 nonce) public view returns (bool) {
        uint256 wordIndex = nonce / 256;
        uint256 bitIndex = nonce % 256;
        bytes32 mask = Mask << (255 - bitIndex);
        return uint256(mask & Unclaimed[wordIndex]) != 0;
    }

    function validClaim(
        address recipient,
        uint16 nonce,
        bytes memory claim
    ) public view returns (bool) {
        bytes32 m = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                          abi.encodePacked("curioglobe", recipient, nonce)
                )
            )
        );

        uint8 v;
        bytes32 r;
        bytes32 s;

        require(claim.length == 65, "Malformed Claim");

        assembly {
            r := mload(add(claim, 32))
            s := mload(add(claim, 64))
            v := byte(0, mload(add(claim, 96)))
        }

        return (ecrecover(m, v, r, s) == claimSigner);
    }

    function processClaim (address recipient, uint16 nonce, bytes memory claim) internal {
        require(availableClaims > 0, "No claims available");
        require(claimingOpen, "Claiming Closed");
        require(isStillAvailable(nonce), "Used Nonce");
        require(nonce < 4976, "Invalid Nonce");
        require(validClaim(recipient, nonce, claim), "Invalid Claim");
        clearClaimBit(nonce);
        availableClaims--;
    }

}