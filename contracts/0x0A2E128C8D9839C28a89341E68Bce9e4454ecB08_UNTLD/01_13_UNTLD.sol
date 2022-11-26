// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract UNTLD is ERC721, ERC721URIStorage, Ownable {
    
    using Strings for string;

    //INTERNAL VARIABLES
    
    using Counters for Counters.Counter;

    bool public isPublicMintEnabled;
    address public _crossmintAddress;
    uint256 public price;

    Counters.Counter private _tokenIdCounter;
    constructor() ERC721("UNTLD", "UTLD") {
        _crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
        price = 0.02 ether;
    }

    //MODIFIERS

    modifier isAvailable() {
        require(isPublicMintEnabled, "minting is not enabled");
        _;
    }

    modifier isCrossMint() {
        require(
            msg.sender == _crossmintAddress,
            "This function is for Crossmint only."
        );
        _;
    }

    //HELPER

    function verify(address _to, string memory uri, address signer, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        
        bytes32 payloadHash = keccak256(abi.encode(_to, uri));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
        address actualSigner = ecrecover(messageHash, v, r, s);
        require(signer == actualSigner, "Wrong signature");
        return true;
    }

    //MINT

    function mint(string memory uri, uint8 v, bytes32 r, bytes32 s)
     public payable 
     isAvailable 
    {
        require(price == msg.value, "Not enough ETH sent, check the price");
        require(verify(msg.sender, uri, owner(), v, r, s), "Not the right signature");
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, uri);
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

    function setMintPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}