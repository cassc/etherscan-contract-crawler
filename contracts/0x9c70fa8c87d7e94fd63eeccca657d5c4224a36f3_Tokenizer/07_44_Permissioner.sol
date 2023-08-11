// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { IPToken, Metadata } from "./IPToken.sol";

error InvalidSignature();
error Denied();

interface IPermissioner {
    /**
     * @notice reverts when `_for` may not interact with `tokenContract`
     * @param tokenContract IPToken
     * @param _for address
     * @param data bytes
     */
    function accept(IPToken tokenContract, address _for, bytes calldata data) external;
}

contract BlindPermissioner is IPermissioner {
    function accept(IPToken tokenContract, address _for, bytes calldata data) external {
        //empty
    }
}

contract ForbidAllPermissioner is IPermissioner {
    function accept(IPToken, address, bytes calldata) external pure {
        revert Denied();
    }
}

contract TermsAcceptedPermissioner is IPermissioner {
    event TermsAccepted(address indexed tokenContract, address indexed signer, bytes signature);

    /**
     * @notice checks validity signer`'s `signature` of `specificTermsV1` on `tokenId` and emits an event
     *         reverts when `signature` can't be verified
     * @dev the signature itself or whether it has already been presented is not stored on chain
     *      uses OZ:`SignatureChecker` under the hood and also supports EIP1271 signatures
     *
     * @param tokenContract IPToken
     * @param _for address the account that has created `signature`
     * @param signature bytes encoded signature, for eip155: `abi.encodePacked(r, s, v)`
     */
    function accept(IPToken tokenContract, address _for, bytes calldata signature) external {
        if (!isValidSignature(tokenContract, _for, signature)) {
            revert InvalidSignature();
        }
        emit TermsAccepted(address(tokenContract), _for, signature);
    }

    /**
     * @notice checks whether `signer`'s `signature` of `specificTermsV1` on `tokenContract.metadata.ipnftId` is valid
     * @param tokenContract IPToken
     */
    function isValidSignature(IPToken tokenContract, address signer, bytes calldata signature) public view returns (bool) {
        bytes32 termsHash = ECDSA.toEthSignedMessageHash(bytes(specificTermsV1(tokenContract)));
        return SignatureChecker.isValidSignatureNow(signer, termsHash, signature);
    }

    function specificTermsV1(Metadata memory metadata) public view returns (string memory) {
        return string.concat(
            "As an IP token holder of IPNFT #",
            Strings.toString(metadata.ipnftId),
            ", I accept all terms that I've read here: ipfs://",
            metadata.agreementCid,
            "\n\n",
            "Chain Id: ",
            Strings.toString(block.chainid),
            "\n",
            "Version: 1"
        );
    }

    /**
     * @notice this yields the message text that claimers must present to proof they have accepted all terms
     * @param tokenContract IPToken
     */
    function specificTermsV1(IPToken tokenContract) public view returns (string memory) {
        return (specificTermsV1(tokenContract.metadata()));
    }
}