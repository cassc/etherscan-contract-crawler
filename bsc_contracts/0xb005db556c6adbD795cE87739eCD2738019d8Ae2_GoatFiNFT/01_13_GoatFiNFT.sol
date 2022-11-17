// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract GoatFiNFT is ERC721, Ownable {
    using Counters for Counters.Counter;


    Counters.Counter tokenId_;
    address public signer;
    string baseURI;
    mapping (bytes => bool) isUsedSignature;

    constructor(address _signer) ERC721("GFI", "GFI") {
        signer = _signer;
        tokenId_._value = 10000;
    }


    /*================================ EVENTS ================================*/

    event TransferSigner(
        address previousSigner,
        address newSigner
    );

    event ClaimNFT(
        uint256 tokenId,
        string internalId,
        address account
    );

    /*================================ FUNCTIONS ================================*/

    /**
     * @dev set new base uri
     * @param _newURI the new uri
     */
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function _baseURI() internal view override returns (string memory){
        return baseURI;
    }

    /**
     * @dev Function Claim NFT when Gacha
     * @param internalId: Internal Nft Id
     * @param signature: the signature
    */
    function claimNFT(string memory internalId, bytes memory signature) external {
        require(!isUsedSignature[signature],"This signature has been used");
        require(verifyClaim(msg.sender, internalId, signature), "Invalid Signature");
        isUsedSignature[signature] = true;
        // mint NFT
        uint256 _tokenId = _handleMint(msg.sender);
        emit ClaimNFT(_tokenId, internalId, msg.sender);
    }

    /**
     * @dev Function handle mint action, return Token ID
     * @param _account: address receives NFT
    */

    function _handleMint(address _account) internal returns(uint256){
            tokenId_.increment();
            _safeMint(_account, tokenId_.current(), "");
            return tokenId_.current();
    }


    /*================================ VERIFY SIGNATURES ================================*/

    /**
     * @dev Set signer to a new account (`setSigner`).
     * Can only be called by the current owner.
    */
    function setSigner(address newSigner) external onlyOwner{
        require(
            newSigner != address(0),
            "GoatFiNFT: New signer is zero address"
        );
        _setSigner(newSigner);
    }

    /**
     * @dev Set signer to a new account (`_newSigner`).
     * Internal function without access restriction.
    */
    function _setSigner(address _newSigner) internal {
        address previousSigner = signer;
        signer = _newSigner;
        emit TransferSigner(previousSigner, signer);
    }

    /**
     * @dev Return Message Hash
     * @param _to: address of user claim MergeNFT
     * @param _internalId: internal Id of NFT
    */
    function getMessageHashClaim(
       address _to,string memory _internalId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _internalId));
    }

    /**
     * @dev Return ETH Signed Message Hash
     * @param _messageHash: Message Hash
    */
    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }
    /**
     * @dev Return True/False
     * @param _to: address of user claim reward
     * @param _internalId: url image of NFT
     * @param signature: sign the message hash offchain
    */
    function verifyClaim(
        address _to,string memory _internalId, bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHashClaim(_to, _internalId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    /**
     * @dev Return address of signer
     * @param _ethSignedMessageHash: ETH Signed Message Hash
     * @param _signature: sign the message hash offchain
    */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev Return split Signature
     * @param sig: sign the message hash offchain
    */
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

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }
}