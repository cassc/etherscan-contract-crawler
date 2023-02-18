// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC721A.sol";

contract LKPass is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

    using Strings for uint256;

    mapping (address => uint256) private mintedWL;

    uint256 public maxSupply = 1000;
    uint256 private pricePublic = 0.1 ether;
    uint256 private priceWL = 0 ether;
    uint256 public maxPerTx = 10;
    uint256 public maxPerWL = 1;
    bytes32 public merkleRootWL = "";
    string public baseURI = "";
    bool public paused = false;
    
    event Minted(address caller);

    constructor() ERC721A("Lovekravt", "LK") {}
    
    function mintPublic(uint256 qty, address to) external payable nonReentrant{
        
        require(!paused, "Minting is paused");
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        require(qty <= maxPerTx, "Sorry, too many per transaction");
        require(msg.value >= pricePublic * qty, "Sorry, not enough amount sent!"); 
        
        _safeMint(to, qty);

        emit Minted(to);
    }

    function mintWL(bytes32[] memory proof) external payable nonReentrant{
        
        require(!paused, "Minting is paused");
        uint256 supply = totalSupply();
        require(supply + 1 <= maxSupply, "Sorry, not enough left!");
        require(msg.value >= priceWL, "Sorry, not enough amount sent!"); 
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verify(leaf, proof), "Sorry, you are not listed for whitelist");
        require(mintedWL[msg.sender] < maxPerWL, "Sorry, you already own the max allowed");
        

        mintedWL[msg.sender] += 1;
        _safeMint(msg.sender, 1);
        emit Minted(msg.sender);
    }

    function mintGiveaway(address _to, uint256 qty) external onlyOwner{
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        _safeMint(_to, qty);
    }
    
    function remaining() public view returns(uint256){
        uint256 left = maxSupply - totalSupply();
        return left;
    }

    function getPriceWL() public view returns(uint256){
        return priceWL;
    }

    function getPricePublic() public view returns (uint256){
        return pricePublic;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = baseURI;
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
    }

    // verify merkle tree leaf
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool){
        return MerkleProof.verify(proof, merkleRootWL, leaf);
    }

    function getOwners() public view returns(address[] memory){
        uint totalSupply = totalSupply();
        address[] memory owners = new address[](totalSupply);
        for(uint256 i = 0; i < totalSupply; i++){
            owners[i] = ownerOf(i);
        }
        return owners;
    }


    // ADMIN FUNCTIONS

    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    function closeMinting() public onlyOwner {
        uint256 supply = totalSupply();
        maxSupply = supply;
    }
    
    function setMaxPerWL(uint256 _max) public onlyOwner {
        maxPerWL = _max;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function setPricePublic(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }

    function setPriceWL(uint256 _newPrice) public onlyOwner {
        priceWL = _newPrice;
    }

    function setMaxPerTx(uint256 _newMax) public onlyOwner {
        maxPerTx = _newMax;
    }

    function setMerkleRootWL(bytes32 _merkleRoot) public onlyOwner {
        merkleRootWL = _merkleRoot;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    // royalties overrides
    
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId, data);
    }

    receive() external payable {}
    
}