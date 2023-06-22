// SPDX-License-Identifier: MIT
// OpenGem Contracts (contracts/ERC721/extensions/Example.sol)

pragma solidity ^0.8.9;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@opengem/contracts/token/ERC721/extensions/ERC721PermanentURIs.sol";
import "@opengem/contracts/token/ERC721/extensions/ERC721PermanentProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Factory is 
    DefaultOperatorFilterer,
    ReentrancyGuard,
    ERC721,
    ERC721Enumerable,
    ERC721PermanentURIs,
    ERC721PermanentProof,
    ERC2981,
    Ownable
    {

    string private uriForFetchingOnly;
    string private contractUriFetching;
    
    address private paidWallet;
    address private factoryWallet = 0xD3E0f2b17Bb9b73637db31bfE535D4F768d2eD73;

    string public artworkBackupTx;
    string public artworkTitle;
    string public artworkDescription;
    string public artworkArtist;

    uint256 public price;
    uint256 public maxSupply;

    constructor(
        string[] memory _collectionInfo,
        string[] memory _artworkInfo,
        string[] memory _uris,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _selfNfts,
        uint96 _royaltyPercent
    ) ERC721(_collectionInfo[0], _collectionInfo[1]) {
        artworkTitle = _artworkInfo[0];
        artworkDescription = _artworkInfo[1];
        artworkArtist = _artworkInfo[2];
        _addPermanentGlobalURI(_uris[0]);
        _addPermanentGlobalURI(_uris[1]);
        contractUriFetching = _uris[2];
        uriForFetchingOnly = _uris[3];
        _setPermanentGlobalProof(_uris[4]);
        price = _price;
        maxSupply = _maxSupply;
        _setDefaultRoyalty(msg.sender, _royaltyPercent);
        paidWallet = msg.sender;

        for (uint256 i = 1; i <= _selfNfts; i++) {
            require(i < _maxSupply, "Collection soldout");
            _safeMint(msg.sender, i);
        }

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return uriForFetchingOnly;
    }

    function contractURI() public view returns (string memory) {
        return contractUriFetching;
    }

    function closeAndLockSales() external onlyOwner {
        maxSupply = totalSupply();
    }

    function setArtworkBackupTx(string calldata _tx) external onlyOwner {
        require(bytes(artworkBackupTx).length == 0, "Backup locked.");
        artworkBackupTx = _tx;
    }

    function updatePaidWallet(address _paidWallet) external onlyOwner {
        paidWallet = _paidWallet;
    }

    function updateUriForFetchingOnly(string calldata _uriForFetchingOnly) external onlyOwner {
        uriForFetchingOnly = _uriForFetchingOnly;
    }

    function addPermanentGlobalURI(string calldata _permanentGlobalUri) external onlyOwner {
        _addPermanentGlobalURI(_permanentGlobalUri);
    }

    function mint() public payable nonReentrant {
        require(totalSupply() < maxSupply, "Collection soldout");
        require(msg.value >= price, "Amount sent is not correct");

        payable(factoryWallet).transfer(msg.value * 30/100);
        payable(paidWallet).transfer(msg.value * 70/100);

        uint256 tokenId = totalSupply() + 1;

        _safeMint(msg.sender, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721PermanentURIs, ERC721PermanentProof)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
        {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}