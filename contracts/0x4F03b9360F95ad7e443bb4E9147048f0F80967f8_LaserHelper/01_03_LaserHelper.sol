// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../interfaces/IEIP1271.sol";
import "../interfaces/ILaserState.sol";

/**
 * @title LaserHelper
 *
 * @notice Allows to batch multiple requests in a single rpc call.
 */
contract LaserHelper {
    error Utils__returnSigner__invalidSignature();

    error Utils__returnSigner__invalidContractSignature();

    // @notice This is temporary, all of this code does not go here.

    /**
     * @param signedHash  The hash that was signed.
     * @param signatures  Result of signing the has.
     * @param pos         Position of the signer.
     *
     * @return signer      Address that signed the hash.
     */
    function returnSigner(
        bytes32 signedHash,
        bytes memory signatures,
        uint256 pos
    ) external view returns (address signer) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r, s, v) = splitSigs(signatures, pos);

        if (v == 0) {
            // If v is 0, then it is a contract signature.
            // The address of the contract is encoded into r.
            signer = address(uint160(uint256(r)));

            // The signature(s) of the EOA's that control the target contract.
            bytes memory contractSignature;

            assembly {
                contractSignature := add(signatures, s)
            }

            if (IEIP1271(signer).isValidSignature(signedHash, contractSignature) != 0x1626ba7e) {
                revert Utils__returnSigner__invalidContractSignature();
            }
        } else if (v > 30) {
            signer = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signedHash)),
                v - 4,
                r,
                s
            );
        } else {
            signer = ecrecover(signedHash, v, r, s);
        }

        if (signer == address(0)) revert Utils__returnSigner__invalidSignature();
    }

    /**
     * @dev Returns the r, s and v values of the signature.
     *
     * @param pos Which signature to read.
     */
    function splitSigs(bytes memory signatures, uint256 pos)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            let sigPos := mul(0x41, pos)
            r := mload(add(signatures, add(sigPos, 0x20)))
            s := mload(add(signatures, add(sigPos, 0x40)))
            v := byte(0, mload(add(signatures, add(sigPos, 0x60))))
        }
    }

    function getLaserState(address laserWallet)
        external
        view
        returns (
            address owner,
            address[] memory guardians,
            address[] memory recoveryOwners,
            address singleton,
            bool _isLocked,
            uint256 configTimestamp,
            uint256 nonce,
            uint256 balance,
            address oldOwner
        )
    {
        ILaserState laser = ILaserState(laserWallet);

        owner = laser.owner();
        guardians = laser.getGuardians();
        recoveryOwners = laser.getRecoveryOwners();
        singleton = laser.singleton();
        (configTimestamp, _isLocked, oldOwner) = laser.getConfig();
        nonce = laser.nonce();
        balance = address(laserWallet).balance;
    }
}