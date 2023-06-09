// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TheMagicFairies is ERC721, Ownable, DefaultOperatorFilterer {

    uint public publicPrice = 0.01 ether;
    uint public presalePrice = 0.005 ether;
    uint public maxSupply = 4444;
    uint public maxTx = 20;
    uint public nonce = 0;

    bytes32 public merkleRoot;

    bool private mintOpen = false;
    bool private presaleOpen = false;

    string internal baseTokenURI = '';
    
    constructor() ERC721("The Magic Fairies", "TMF") {}

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function togglePresale() external onlyOwner {
        presaleOpen = !presaleOpen;
    }
    
    function setPresalePrice(uint newPrice) external onlyOwner {
        presalePrice = newPrice;
    }

    function setPublicPrice(uint newPrice) external onlyOwner {
        publicPrice = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
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

    function mintPresale(uint qty, bytes32[] memory proof) external payable {
        require(presaleOpen, "store closed");
        require(verify(proof), "address not in whitelist");
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        require(msg.value >= presalePrice * qty, "PAYMENT: invalid value");
        _mintTo(_msgSender(), qty);
    }
    
    function mintPublic(uint qty) external payable {
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

    function verify(bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, merkleRoot, leaf);
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