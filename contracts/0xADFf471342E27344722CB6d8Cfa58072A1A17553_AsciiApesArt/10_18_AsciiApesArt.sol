// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./libraries/AsciiApesArtMetadata.sol";
import "./libraries/Utils.sol";

contract AsciiApesArt is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {
    bool public isMintLive = true;
    uint256 public mintPrice = 0.003 ether;
    uint256 public maxSupply = 10000;

    mapping(uint256 => uint256) private seeds;
    
    constructor() ERC721A("AsciiApes Art", "AAA") {
        _setDefaultRoyalty(msg.sender, 600);
    }

    function mint(uint256 quantity) external payable {
        require(isMintLive, "Mint Not Live");
        require(quantity > 0, "QTY more than 0");
        require(msg.value >= quantity * mintPrice, "Not enough eth");
        require(totalSupply() + quantity <= maxSupply, "Exceeds total supply");

        uint256 nextTokenId = _nextTokenId();

        for (uint256 i = nextTokenId; i < nextTokenId + quantity; i++) {
            seeds[i] = generateSeed(i);
        }
        
        _mint(msg.sender, quantity);
    }

    function giveaway(address to, uint256 quantity) external onlyOwner {
        require(quantity > 0, "QTY more than 0");
        require(totalSupply() + quantity <= maxSupply, "Exceeds total supply");

        uint256 nextTokenId = _nextTokenId();

        for (uint256 i = nextTokenId; i < nextTokenId + quantity; i++) {
            seeds[i] = generateSeed(i);
        }
        _mint(to, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (tokenId > _totalMinted()) revert URIQueryForNonexistentToken();
        return AsciiApesArtMetadata.tokenURI(tokenId, seeds[tokenId]);
    }

    function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 r = Utils.getRandom(tokenId);
        uint256 headSeed = 100 * (r % 11 + 10) + ((r >> 48) % 20 + 10);
        uint256 faceSeed = 100 * ((r >> 96) % 10 + 10) + ((r >> 96) % 20 + 10);
        uint256 bodySeed = 100 * ((r >> 144) % 8 + 10) + ((r >> 144) % 20 + 10);
        uint256 mouthSeed = 100 * ((r >> 192) % 6 + 10) + ((r >> 192) % 20 + 10);
        return 10000 * (10000 * (10000 * headSeed + faceSeed) + bodySeed) + mouthSeed;
    }

    function updateSeed(uint256 tokenId, uint256 seed) external onlyOwner {
        seeds[tokenId] = seed;
    }

    function toggleMintLive() external onlyOwner {
        isMintLive = !isMintLive;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
    bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        (bool os,)= payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}