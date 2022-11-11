// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract IykykPass is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    mapping (address => uint256) private mintedWL;

    uint256 public maxSupply = 8888;
    uint256 private pricePublic = 0.2 ether;
    uint256 private priceWL = 0.02 ether;
    uint256 public maxPerTxPublic = 10;
    uint256 public maxPerTxWL = 10;
    uint256 public maxPerWalletWL = 10;
    uint256 public maxPerWL = 10;

    string private baseURI = "";
    string public provenance = "";
    string public uriPass = "";
    
    bool public paused = true;
    
    uint256 public saleStatus = 0; // 0 - whitelist, 1 - public
    
    bytes32 public merkleRootWL = "";
    
    event Minted(address caller);

    constructor() ERC721A("iykyk+", "IYKYK") {}
    
    function mintPublic(uint256 count, address to) external payable nonReentrant{
        require(!paused, "Minting is paused");
        require(saleStatus == 1, 'Public mint not active');
        uint256 supply = totalSupply();
        require(supply + count <= maxSupply, "Sorry, not enough left!");
        require(count <= maxPerTxPublic, "Sorry, too many per transaction");
        require(msg.value >= pricePublic * count, "Sorry, not enough amount sent!"); 
        
        _safeMint(to, count);

        emit Minted(to);
    }

    function mintWL(uint256 qty, bytes32[] memory proof) external payable nonReentrant{
        require(!paused, "Minting is paused");
        require(saleStatus == 0, 'Whitelist not active');
        // uint256 supply = totalSupply();
        require(msg.value >= priceWL * qty, "Sorry, not enough amount sent!"); 
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verify(leaf, proof), "Sorry, you are not listed for whitelist");
        require(mintedWL[msg.sender] < maxPerWalletWL, "Sorry, you already own the max allowed");
        require(qty <= maxPerTxWL, "Sorry, too many per transaction");

        mintedWL[msg.sender] += qty;
        _safeMint(msg.sender, qty);
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
        return uriPass;
    }

    // verify merkle tree leaf
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool){
        return MerkleProof.verify(proof, merkleRootWL, leaf);
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

    function setUriPass(string memory _URI) public onlyOwner {
        uriPass = _URI;
    }

    function setPricePublic(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }

    function setPriceWL(uint256 _newPrice) public onlyOwner {
        priceWL = _newPrice;
    }

    function setMaxPerTxPublic(uint256 _newMax) public onlyOwner {
        maxPerTxPublic = _newMax;
    }

    function setMaxPerTxWL(uint256 _newMax) public onlyOwner {
        maxPerTxWL = _newMax;
    }

    function setProvenanceHash(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function setMerkleRootWL(bytes32 _merkleRoot) public onlyOwner {
        merkleRootWL = _merkleRoot;
    }

    function setSaleStatus(uint256 _saleStatus) public onlyOwner {
        saleStatus = _saleStatus;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }



    receive() external payable {}
    
}