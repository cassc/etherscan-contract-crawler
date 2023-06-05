// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "@openzeppelin/utils/cryptography/EIP712.sol";
import "./CurioErrorsAndEvents.sol";

contract CurioEIP712 is
    EIP712, CurioErrorsAndEvents
{
    struct Claim {
        address wallet;
        uint256 tokenId;
        uint256 nonce;
    }

    mapping ( bytes => bool) private _signature_used;

    bytes32 private constant MINTKEY_TYPE_HASH =
        keccak256("Claim(address wallet,uint256 tokenId,uint256 nonce)");

    address private _signer;
    address public vault;

    string private _migratedBaseURI;
    string private _unmigratedBaseURI;

    constructor(
        string memory name_,
        address signer_
    ) EIP712(name_, "1") {
        _setSigner(signer_);
    }

    function _setSigner(address signer) internal {
        _signer = signer;
    }

    function verify(
        bytes calldata signature,
        address wallet,
        uint256 tokenId,
        uint256 nonce
    ) internal returns (bool) {
        if (_signature_used[signature]) {
            revert SignatureAlreadyUsed();
        }

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(MINTKEY_TYPE_HASH, wallet, tokenId, nonce))
        );

        _signature_used[signature] = true;

        return ECDSA.recover(digest, signature) == _signer;
    }
}