// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC1271 } from "lib/openzeppelin-contracts/contracts/interfaces/IERC1271.sol";

/// @title EIP712
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
/// @notice https://eips.ethereum.org/EIPS/eip-712
abstract contract EIP712 {
    /// @dev Invalid signature
    error InvalidSignature();

    /// @dev Signature is invalid (IERC1271)
    error IERC1271InvalidSignature();

    /// @notice Gets the domain separator
    /// @dev DOMAIN_SEPARATOR should be unique to the contract and chain to prevent replay attacks from
    /// other domains, and satisfy the requirements of EIP-712
    /// @return bytes32 the domain separator
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32);

    /// @notice Checks if signer's signature matches the data
    /// @param signer address of the signer
    /// @param hashStruct hash of the typehash & abi encoded data, see https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct]
    /// @param v recovery identifier
    /// @param r signature parameter
    /// @param s signature parameter
    /// @return bool true if the signature is valid, false otherwise
    function _verifySig(
        address signer,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(signer)
        }

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hashStruct));

        if (size > 0) {
            // signer is a contract
            if (
                IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) !=
                IERC1271(signer).isValidSignature.selector
            ) {
                revert IERC1271InvalidSignature();
            }
        } else {
            // EOA signer
            address recoveredAddress = ecrecover(digest, v, r, s);

            if (recoveredAddress == address(0) || recoveredAddress != signer) {
                revert InvalidSignature();
            }
        }

        return true;
    }
}