// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library ECDSA {
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    function ethSignedMessage(bytes32 hashedMessage)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    hashedMessage
                )
            );
    }
}

abstract contract SignatureVerifier {
    using ECDSA for bytes32;

    address public TRUSTED_PARTY;

    mapping(uint256 => bool) public nonceUsed;

    mapping(address => bool) public isOperators;

    modifier unusedNonce(uint256 nonce) {
        require(!nonceUsed[nonce], "Nonce being used");
        _;
    }

    modifier onlyOperator() {
        require(isOperators[msg.sender], "caller not operator");
        _;
    }

    // set address operator
    function setOperator(address _operator, bool _status) external onlyOperator {
        isOperators[_operator] = _status;
    }

    function setTrustedParty(address _trusted) external onlyOperator {
        TRUSTED_PARTY = _trusted;
    }

    // verify claim eth reward
    function verifyClaimCampaign(
        address receiver,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory campaignIds,
        uint256 nonce,
        bytes memory signature
    ) internal unusedNonce(nonce) returns (bool) {
        address signer = keccak256(
            abi.encode(receiver, tokens, amounts, campaignIds, nonce)
        ).ethSignedMessage().recover(signature);
        require(
            signer == TRUSTED_PARTY,
            "ShinikiCampaign: Invalid signature claim NFT"
        );
        nonceUsed[nonce] = true;
        return true;
    }
}