// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/ISignatureVerifier.sol";

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

contract SignatureVerifier is
    ISignatureVerifier,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using ECDSA for bytes32;

    address public TRUSTED_PARTY;

    mapping(uint256 => bool) public nonceUsed;

    modifier unusedNonce(uint256 nonce) {
        require(!nonceUsed[nonce], "Nonce being used");
        _;
    }

    function initialize(address _trusted) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        TRUSTED_PARTY = _trusted;
    }

    function setTrustedParty(address _trusted) external onlyOwner {
        TRUSTED_PARTY = _trusted;
    }

    // verify claim reward
    function verifyClaim(
        address token,
        address receiver,
        uint256 maxAllowce,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    )
        public
        override
        nonReentrant
        whenNotPaused
        unusedNonce(nonce)
        returns (bool)
    {
        address signer = keccak256(
            abi.encode(token, receiver, maxAllowce, amount, nonce)
        ).ethSignedMessage().recover(signature);
        require(signer == TRUSTED_PARTY, "Shiniki: Invalid signature claim");
        nonceUsed[nonce] = true;
        return true;
    }

    // verify mint pre
    function verifyPreSaleMint(
        address receiver,
        bytes32[] memory typeMints,
        uint256[] memory quantities,
        uint256 amountAllowce,
        uint256 nonce,
        bytes memory signature
    )
        public
        override
        nonReentrant
        whenNotPaused
        unusedNonce(nonce)
        returns (bool)
    {
        address signer = keccak256(
            abi.encode(receiver, typeMints, quantities, amountAllowce, nonce)
        ).ethSignedMessage().recover(signature);
        require(signer == TRUSTED_PARTY, "Shiniki: Invalid signature preSale");
        nonceUsed[nonce] = true;
        return true;
    }

    // verifyTransferOwner
    function verifyTransferOwner(
        address newOwner,
        uint256 nonce,
        bytes memory signature
    )
        public
        override
        nonReentrant
        whenNotPaused
        unusedNonce(nonce)
        returns (bool)
    {
        address signer = keccak256(abi.encode(newOwner, nonce))
            .ethSignedMessage()
            .recover(signature);
        require(
            signer == TRUSTED_PARTY,
            "Shiniki: Invalid signature transferOwner"
        );
        nonceUsed[nonce] = true;
        return true;
    }

    // verifyClaimAirdrop
    function verifyClaimAirdrop(
        address receiver,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    )
        public
        override
        nonReentrant
        whenNotPaused
        unusedNonce(nonce)
        returns (bool)
    {
        address signer = keccak256(abi.encode(receiver, amount, nonce))
            .ethSignedMessage()
            .recover(signature);
        require(
            signer == TRUSTED_PARTY,
            "Shiniki: Invalid signature claim airdrop"
        );
        nonceUsed[nonce] = true;
        return true;
    }

    function setUsedNonce(uint256 nonce) public onlyOwner {
        nonceUsed[nonce] = true;
    }
}