// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @title An abstract contract that checks if the verified slot is valid
* @author Oost & Voort, Inc
* @notice This contract is to be used in conjunction with the AccessPassNFT contract
*/

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IVerifiedSlot.sol";

abstract contract WhitelistVerifier is IVerifiedSlot {
    using ECDSA for bytes32;

    /**
    * @dev The following struct follows the EIP712 Standard
    */
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    /**
    * @dev The typehash for EIP712Domain
    */
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    /**
    * @dev The typehash for the message being sent to the contract
    */
    bytes32 constant VERIFIED_SLOT_TYPEHASH =
        keccak256("VerifiedSlot(address minter,uint256 mintingCapacity)");

    /**
    * @dev The hashed Domain Message
    */
    bytes32 DOMAIN_SEPARATOR;

    /**
    * @dev the address of the whiteListSigner which is an EOA that signs a message that confirms who can mint how much
    */
    address public whiteListSigner;

    /**
    * @dev emitted when the whitelistSigner has been set
    * @param oldSigner represents the old signer for the Contract
    * @param newSigner represents the newly set signer for the Contract
    */
    event WhitelistSignerSet(address oldSigner, address newSigner);

    /**
    * @dev reverts with this message when the Zero Address is being used to set the Whitelist Signer
    */
    error WhitelistSignerIsZeroAddress();

    /**
    * @dev reverts with this message when the Caller of the mint is not the same as the one in the VerifiedSLot
    * @param caller is the account that called for the mint
    * @param minter is the address specified in the VerifiedSlot
    */
    error CallerIsNotMinter(address caller, address minter);

    /**
    * @dev reverts with this message when the message is not correct or if it is not signed by the WhitelistSigner
    * @param unknownSigner is the signer that signed the message
    * @param whitelistSigner is the signer who should have signed the message
    */
    error UnknownSigner(address unknownSigner, address whitelistSigner);

    /**
    * @dev reverts with this message when the caller is trying to mint more than allowed
    * @param minted is the amount of tokens the caller has minted already
    */
    error ExceedMintingCapacity(uint256 minted);

    /**
    * @notice initializes the contract
    */
    constructor () {
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "AccessPassNFT",
            version: '1',
            chainId: block.chainid,
            verifyingContract: address(this)
        }));
    }

    /**
    * @notice sets the whitelistSigner
    * @param whitelistSigner_ is an EOA that signs verified slots
    */
    function _setWhiteListSigner(address whitelistSigner_) internal virtual {
        if (whitelistSigner_ == address(0)) revert WhitelistSignerIsZeroAddress();

        emit WhitelistSignerSet(whiteListSigner, whitelistSigner_);
        whiteListSigner = whitelistSigner_;

    }

    /**
    * @notice validates verified slot
    * @param minter is msg.sender
    * @param minted is the amount the minter has minted
    * @param verifiedSlot is an object with the following:
    * minter: address of the minter,
    * mintingCapacity: amount Metaframes has decided to grant to the minter,
    * r and s --- The x co-ordinate of r and the s value of the signature
    * v: The parity of the y co-ordinate of r
    */
    function validateVerifiedSlot(
        address minter,
        uint256 minted,
        VerifiedSlot memory verifiedSlot
    ) internal view
    {
        if (whiteListSigner == address(0)) revert WhitelistSignerIsZeroAddress();
        if (verifiedSlot.minter != minter) revert CallerIsNotMinter(minter, verifiedSlot.minter);
        if(verifiedSlot.mintingCapacity <= minted) revert ExceedMintingCapacity(minted);

        address wouldBeSigner = getSigner(verifiedSlot);
        if (wouldBeSigner != whiteListSigner) revert UnknownSigner(wouldBeSigner, whiteListSigner);
    }

    /**
    * @notice hashes the DOMAIN object using keccak256
    * @param eip712Domain represents the EIP712 object to be hashed
    */
    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            ));
    }

    /**
    * @notice hashes the verifiedslot object using keccak256
    * @param verifiedSlot is an object with the following:
    * minter: address of the minter,
    * mintingCapacity: amount Metaframes has decided to grant to the minter,
    * r and s --- The x co-ordinate of r and the s value of the signature
    * v: The parity of the y co-ordinate of r
    */
    function hash(VerifiedSlot memory verifiedSlot) internal pure returns (bytes32) {
        return
        keccak256(abi.encode(
            VERIFIED_SLOT_TYPEHASH,
            verifiedSlot.minter,
            verifiedSlot.mintingCapacity
        ));
    }

    /**
    * @notice returns the signer of a given verifiedSlot to be used to check who signed the message
    * @param verifiedSlot is an object with the following:
    * minter: address of the minter,
    * mintingCapacity: amount Metaframes has decided to grant to the minter,
    * r and s --- The x co-ordinate of r and the s value of the signature
    * v: The parity of the y co-ordinate of r
    */
    function getSigner(VerifiedSlot memory verifiedSlot) internal view returns (address) {

        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hash(verifiedSlot)
            ));

        return ecrecover(digest, verifiedSlot.v, verifiedSlot.r, verifiedSlot.s);
    }
}