// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

contract BFParty is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;
    uint16 constant MAX_SUPPLY = 4444;

    mapping(address => uint256) public minted;

    address public signerAddress = 0x931A1Cf012d0c304C35E7F2BD27b4AeaB82C9F57;

    bool public publicMintEnabled=false;
    string public baseUri;

    constructor(string memory uri) ERC721A("BFParty", "BFP") {
        baseUri = uri;          
    }

    function setSignerAddress(address newAddress) external onlyOwner {
        signerAddress = newAddress;
    }

    function setBaseUri(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function togglePublicMint() external onlyOwner {
        publicMintEnabled=!publicMintEnabled;
    }

    //just in case of sending eth to this address by mistake.
    function withdraw() external onlyOwner {                
        (bool success, ) = owner().call{value: address(this).balance}("");        
        require(
            success,"withdrawal unsuccessful."
        );
    }

    function safeMint(address to, uint256 quantity) internal {
        require(quantity + totalSupply() <= MAX_SUPPLY, "Max supply exceeded.");
        _safeMint(to, quantity);
    }

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        safeMint(to, quantity);
    }

    function hashTransaction(address sender)
        internal
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender))
            )
        );
        return hash;
    }

    function publicMint() external        
    {
        require(publicMintEnabled,"public mint not enabled");
        require(minted[msg.sender]==0,"already minted");
        minted[msg.sender] += 1;
        safeMint(msg.sender, 1);
    }

    function whitelistMint(bytes memory signature) external{
        require(
            signerAddress ==
                hashTransaction(msg.sender).recover(signature),
            "Direct minting disallowed"
        );
        require(minted[msg.sender]==0,"already minted");
        minted[msg.sender] += 1;
        safeMint(msg.sender, 1);
    }
}