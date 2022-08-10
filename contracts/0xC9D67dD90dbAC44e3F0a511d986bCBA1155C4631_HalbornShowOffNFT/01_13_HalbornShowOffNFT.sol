// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
                                          
import "ERC721.sol";
import "Counters.sol";
import "Ownable.sol";
import "SeraphProtected.sol";

contract HalbornShowOffNFT is SeraphProtected, ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => string) idToUri;

    event ShowOffNftMinted(uint256 _nftId, address _address);
    event ShowOffNftBurnt(uint256 _nftId);
    event MetadataChanged(uint256 _nftId, string _oldMetadata, string _newMetadata);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        string memory nftIdUri = idToUri[tokenId];
        return bytes(nftIdUri).length > 0 ? nftIdUri : "";
    }
    
    function mintNFT(address _receiver, string calldata _metadataUri) external onlyOwner  {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        idToUri[tokenId] = _metadataUri;
        _safeMint(_receiver, tokenId);
        emit ShowOffNftMinted(tokenId, _receiver);
    }

    function burnNFT(uint256 _nftId) external onlyOwner withSeraph() {
        require(_exists(_nftId), "ERC721: invalid token ID");
        _burn(_nftId);
        emit ShowOffNftBurnt(_nftId);
    }

    function mintMultipleNFT(address _receiver, string[] calldata _metadataUris) external onlyOwner {
        uint256 len = _metadataUris.length;
        uint256 tokenId;
        for (uint256 i; i < len; ++i) {
            _tokenIdCounter.increment();
            tokenId = _tokenIdCounter.current();
            idToUri[tokenId] = _metadataUris[i];
            _safeMint(_receiver, tokenId);
            emit ShowOffNftMinted(tokenId, _receiver);
        }
    }

    function changeMetadata(uint256 _nftId, string calldata _newMetadataUri) external onlyOwner withSeraph() {
        require(_exists(_nftId), "ERC721: invalid token ID");
        emit MetadataChanged(_nftId, idToUri[_nftId], _newMetadataUri);
        idToUri[_nftId] = _newMetadataUri;
    }

    function transferOwnership(address newOwner) public override onlyOwner withSeraph() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override withSeraph() {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        revert("safeTransferFrom not allowed");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        revert("safeTransferFrom not allowed");
    }
}