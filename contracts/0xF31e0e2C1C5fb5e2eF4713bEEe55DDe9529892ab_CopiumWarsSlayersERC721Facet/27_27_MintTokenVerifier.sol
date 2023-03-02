//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import { CopiumWarsSlayersStorage } from "./CopiumWarsSlayersStorage.sol";

/**
 * @title Mint Token Verifier
 * @author Tony Snark
 * @notice Abstract contract which isolates EIP-712 contract signature verification
 */
abstract contract MintTokenVerifier is EIP712 {
    error MintTokenVerifier__InvalidSigner();
    error MintTokenVerifier__TokenAlreadyUsed();

    bytes32 public constant MINT_TOKEN_HASHTYPE =
        keccak256("MintToken(uint256 mintTokenId,address recipient,uint256 amount)");

    /* solhint-disable no-empty-blocks */
    constructor(string memory name, string memory version) EIP712(name, version) {}

    /// @dev Validates if a mint token is valid
    function _validateMintToken(
        uint256 mintTokenId,
        address recipient,
        uint256 amount,
        bytes memory signature
    ) internal {
        bytes32 mintTokenHash = _hashMintToken(mintTokenId, recipient, amount);
        if (CopiumWarsSlayersStorage.layout().usedMintTokens[mintTokenId]) revert MintTokenVerifier__TokenAlreadyUsed();
        if (!_verifySigner(mintTokenHash, signature)) revert MintTokenVerifier__InvalidSigner();
        CopiumWarsSlayersStorage.layout().usedMintTokens[mintTokenId] = true;
    }

    /// @dev Calculates mint token hash
    function _hashMintToken(uint256 mintTokenId, address recipient, uint256 amount) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MINT_TOKEN_HASHTYPE, mintTokenId, recipient, amount)));
    }

    /// @dev Verifies the signer is approved
    function _verifySigner(bytes32 digest, bytes memory signature) internal view returns (bool) {
        return CopiumWarsSlayersStorage.layout().theExecutor == ECDSA.recover(digest, signature);
    }
}