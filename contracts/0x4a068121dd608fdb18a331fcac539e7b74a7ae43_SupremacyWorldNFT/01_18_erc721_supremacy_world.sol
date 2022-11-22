// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@imx/contracts/Mintable.sol";
import "./crypto_verifysignatures.sol";

contract SupremacyWorldNFT is
    ERC721,
    ERC721Burnable,
    Ownable,
    Mintable,
    SignatureVerifier
{
    mapping(address => uint256) public nonces;
    string baseURI;

    constructor(
        address _signer,
        address _imx,
        string memory name,
        string memory symbol
    )
        ERC721(name, symbol)
        Mintable(msg.sender, _imx)
        SignatureVerifier(_signer)
    {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function adminSetBaseURI(string calldata newURI) public onlyOwner {
        baseURI = newURI;
    }

    function adminMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function signedMint(
        uint256 tokenId,
        bytes calldata signature,
        uint256 expiry
    ) public {
        require(expiry > block.timestamp, "signature expired");
        bytes32 messageHash = getMessageHash(
            msg.sender,
            address(this),
            tokenId,
            nonces[msg.sender]++,
            expiry
        );
        require(verify(messageHash, signature), "Invalid Signature");
        _safeMint(msg.sender, tokenId);
    }

    function _mintFor(
        address to,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(to, id);
    }

    // getMessageHash builds the hash for signature verification
    function getMessageHash(
        address userAddr,
        address collectionAddr,
        uint256 tokenID,
        uint256 nonce,
        uint256 expiry
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(userAddr, collectionAddr, tokenID, nonce, expiry)
            );
    }
}