// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SignatureManager is AccessControl {
    address signer;
    error SignerNotFound();
    error SignatureRedeemed();
    mapping(bytes => bool) public isRedeemed;

    constructor(address _signer) {
        signer = _signer; 
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setSigner(address _signer)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        signer = _signer;
    }

    function getMessageHash(
        address to,
        uint256 tokenId,
        string memory uri,
        uint8 phase
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(to, tokenId, uri, phase)
            );
    }   

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address owner,
        uint256 tokenId,
        string memory uri,
        uint8 phase,
        bytes memory signature
    ) external returns (bool) {

        if(signer == address(0)) {
            revert SignerNotFound();
        }

        if(isRedeemed[signature]) {
            revert SignatureRedeemed();
        }

        
        bytes32 messageHash = getMessageHash(
            owner,
            tokenId,
            uri,
            phase
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        isRedeemed[signature] = true;

        return
            recoverSigner(ethSignedMessageHash, signature) ==
            signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}