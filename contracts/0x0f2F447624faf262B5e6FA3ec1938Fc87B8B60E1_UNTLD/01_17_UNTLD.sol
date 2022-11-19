// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Signature } from "./Signature.sol";

contract UNTLD is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, Signature {

    using Strings for string;

    //INTERNAL VARIABLES
    
    using Counters for Counters.Counter;

    bool public isPublicMintEnabled;
    address _crossmintAddress;

    Counters.Counter private _tokenIdCounter;
    constructor() ERC721("UNTLD", "UTLD") {

        _crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
    }

    //MODIFIERS

    modifier isAvailable() {
        require(isPublicMintEnabled, 'minting is not enabled');
        _;
    }

    modifier isCrossMint() {
        require(
            msg.sender == _crossmintAddress,
            "This function is for Crossmint only."
        );
        _;
    }

    //MINT

    function mint(address _to, string memory uri, bytes memory signature) public isAvailable returns(uint256) {

        // transaction caller must be recipient
        require(msg.sender == _to, "This isn't yours!");

        // require a valid signature from a member of MINTER_ROLE
        //require(isValidSignature(_to, uri, signature), "You have no power here!");

        require(verify(owner(), _to, uri, signature), "You have no power here!");

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, uri);

        return newTokenId;
    }

    function crossmint(address _to, string memory uri) public payable isCrossMint isAvailable {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(_to, newTokenId);
        _setTokenURI(newTokenId, uri);
    }

    // VIEW

    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return super.tokenURI(_tokenId);
    }

    // ADMIN

    function getTokenId() public view returns(uint){
        return _tokenIdCounter.current();
    }

    function setIsPublicMintEnabled(bool _isPublicMintEnabled) public onlyOwner {
        isPublicMintEnabled = _isPublicMintEnabled;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}