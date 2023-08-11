// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TheNexusCover is ERC721, Ownable, DefaultOperatorFilterer {

    uint public publicPrice = 0.029 ether;
    uint public maxSupply = 3050;
    uint public maxTx = 20;
    uint public nonce = 0;
    uint public edition = 0;

    bool private mintOpen = false;

    string internal baseTokenURI = '';

    IERC1155 public THENEXUS;

    mapping(address => bool) public claimed;
    
    constructor() ERC721("The Nexus Cover", "NEXUSC") {}

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function setEdition(uint ed) external onlyOwner {
        edition = ed;
    }

    function setPublicPrice(uint newPrice) external onlyOwner {
        publicPrice = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function buyTo(address to, uint qty) external onlyOwner {
        _mintTo(to, qty);
    }

    function claimCover() external {
        require(mintOpen, "store closed");
        uint256 balance = THENEXUS.balanceOf(msg.sender, edition);
        require(balance > 0, "You must have at least one The Nexus Comic NFT");
        require(!claimed[_msgSender()], "You cannot claim this again");
        _mintTo(_msgSender(), balance);
        claimed[_msgSender()] = true;
    }

    function setTheNexusAddress(address newAddress) external onlyOwner {
        THENEXUS = IERC1155(newAddress);
    }

    function mint(uint qty) external payable {
        require(mintOpen, "store closed");
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        require(msg.value >= publicPrice * qty, "PAYMENT: invalid value");
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + nonce <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        for(uint i = 0; i < qty; i++){
            uint tokenId = nonce;
            _safeMint(to, tokenId);
            nonce++;
        }
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}