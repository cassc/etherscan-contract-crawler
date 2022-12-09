// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../LazyMint/LazyMintLib.sol";
import "../URIStorage/URIStorageLib.sol";

error CannotMintWithoutSigner();

library OnDemandMintLib {
    bytes32 constant ON_DEMAND_MINT_STORAGE =
        keccak256("on.demand.mint.storage");

    struct OnDemandMintStorage {
        address _mintSigner;
        mapping(address => uint256) _userNonces;
    }

    function onDemandMintStorage()
        internal
        pure
        returns (OnDemandMintStorage storage s)
    {
        bytes32 position = ON_DEMAND_MINT_STORAGE;
        assembly {
            s.slot := position
        }
    }

    function getMintSigner() internal view returns (address) {
        return onDemandMintStorage()._mintSigner;
    }

    function setMintSigner(address _nextMintSigner) internal {
        onDemandMintStorage()._mintSigner = _nextMintSigner;
    }

    function _verifyApprovalSignature(
        string memory tokenURI,
        bytes memory approvalSignature
    ) internal {
        OnDemandMintStorage storage s = onDemandMintStorage();
        if (s._mintSigner == address(0)) {
            revert CannotMintWithoutSigner();
        }

        bytes memory signedBytes = abi.encode(
            msg.sender,
            address(this),
            s._userNonces[msg.sender]++,
            tokenURI
        );
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(signedBytes);
        address signer = ECDSA.recover(ethHash, approvalSignature);

        require(signer == s._mintSigner, "ON DEMAND MINT: invalid signature");
    }

    function onDemandMint(
        string memory _tokenURI,
        bytes memory approvalSignature
    ) internal {
        _verifyApprovalSignature(_tokenURI, approvalSignature);
        uint256 tokenId = LazyMintLib.publicMint(1);
        URIStorageLib.setTokenURI(tokenId, _tokenURI);
    }
}