// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract VerifySignature is Ownable {
    using ECDSA for bytes32;

    // The version of signatures that are valid
    string private _signVersion;

    // The wallet that signed the data
    address private _signerWallet;

    constructor(string memory signVersion_, address signerWallet_){
        _signVersion = signVersion_;
        _signerWallet = signerWallet_;
    }

    /**
     * @dev External function to update the signer version if a change is required.
     *      This can only be accessed by the owner of the contract
     *      NOTE: This will not allow any previous signatures made to be used
     *
     * @param signVersion_ a new version string to be used during verification
     */
    function updateSignVersion(string calldata signVersion_) external onlyOwner {
        _signVersion = signVersion_;
    }

    /**
     * @dev External function to update the signer wallet if a change is required
     *      This can only be accessed by the owner of the contract
     *      NOTE: This will not allow any previous signatures made to be used
     *
     * @param signerWallet_ the new wallet to be the signerWallet
     */
    function updateSignerWallet(address signerWallet_) external onlyOwner {
       _signerWallet = signerWallet_;
    }

    /**
     * @dev Internal function to validate a signatures data.
     *
     * @param sender the address who sent the signature to the contract
     * @param tokenId the id the number of the token that can be minted
     * @param nonce to mark the signature has been used
     * @param signature the signature created by the signerWallet
     * @return bool whether the signature matches the passed data or not
     */
    function _verify(
        address sender,
        uint256 tokenId,
        uint256 nonce,
        bytes memory signature
    ) internal view returns (bool) {
        return keccak256(abi.encodePacked(sender, _signVersion, tokenId, nonce))
            .toEthSignedMessageHash()
            .recover(signature) == _signerWallet;
    }
}