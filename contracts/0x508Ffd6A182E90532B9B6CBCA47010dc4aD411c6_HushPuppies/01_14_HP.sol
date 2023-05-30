//       ___                               ___                                                                             
//      (   )                             (   )                                                  .-.                       
//       | | .-.    ___  ___      .--.     | | .-.        .-..    ___  ___     .-..      .-..   ( __)   .--.       .--.    
//       | |/   \  (   )(   )   /  _  \    | |/   \      /    \  (   )(   )   /    \    /    \  (''")  /    \    /  _  \   
//       |  .-. .   | |  | |   . .' `. ;   |  .-. .     ' .-,  ;  | |  | |   ' .-,  ;  ' .-,  ;  | |  |  .-. ;  . .' `. ;  
//       | |  | |   | |  | |   | '   | |   | |  | |     | |  . |  | |  | |   | |  . |  | |  . |  | |  |  | | |  | '   | |  
//       | |  | |   | |  | |   _\_`.(___)  | |  | |     | |  | |  | |  | |   | |  | |  | |  | |  | |  |  |/  |  _\_`.(___) 
//       | |  | |   | |  | |  (   ). '.    | |  | |     | |  | |  | |  | |   | |  | |  | |  | |  | |  |  ' _.' (   ). '.   
//       | |  | |   | |  ; '   | |  `\ |   | |  | |     | |  ' |  | |  ; '   | |  ' |  | |  ' |  | |  |  .'.-.  | |  `\ |  
//       | |  | |   ' `-'  /   ; '._,' '   | |  | |     | `-'  '  ' `-'  /   | `-'  '  | `-'  '  | |  '  `-' /  ; '._,' '  
//      (___)(___)   '.__.'     '.___.'   (___)(___)    | \__.'    '.__.'    | \__.'   | \__.'  (___)  `.__.'    '.___.'   
//                                                      | |                  | |       | |                                 
//                                                     (___)                (___)     (___)                                
//
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract HushPuppies is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    bytes32 public merkleRootFree = "";
    bytes32 public merkleRootWL = "";

    mapping (address => uint256) private mintedFree;
    mapping (address => uint256) private mintedWL;

    uint256 public maxSupply = 7777;
    uint256 private priceWL = 0.0077 ether;
    uint256 private pricePublic = 0.0077 ether;
    
    uint256 public maxPerTx = 10;
    uint256 public qtyFree = 2222;
    uint256 public maxPerWalletFree = 3;
    uint256 public maxPerWalletWL = 10;

    string private baseURI = "";
    string public provenance = "";
    string public uriNotRevealed = "";
    
    uint256 public saleStatus = 0; // 0 - free, 1 - whitelist, 2 - public
    bool public paused = true;
    bool public isRevealed;
    
    event Minted(address caller);
    
    constructor() ERC721A("Hush Puppies", "HP") {}

    // verify merkle tree leaf
    function _verify(bytes32 leaf, bytes32[] memory proof, bool isFree) internal view returns (bool){
        if(isFree){
            return MerkleProof.verify(proof, merkleRootFree, leaf);
        }else{
            return MerkleProof.verify(proof, merkleRootWL, leaf);
        }
    }

    // mints a free token to the caller
    function mintFree(uint256 qty, bytes32[] memory proof) public nonReentrant {
        require(!paused, "Minting is paused");
        require(saleStatus == 0, 'Free mint not active');
        uint256 supply = totalSupply();
        require(supply < qtyFree, "Sorry, we ran out of free ones!");
        require(mintedFree[msg.sender] < maxPerWalletFree, "Sorry, you already own the max allowed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verify(leaf, proof, true), "Sorry, you are not listed for free mint");

        mintedFree[msg.sender] += qty;
        _safeMint(msg.sender, qty);
        emit Minted(msg.sender);
    }
    
    function mintWL(uint256 qty, bytes32[] memory proof) external payable nonReentrant{
        require(!paused, "Minting is paused");
        require(saleStatus == 1, 'Whitelist not active');
        // uint256 supply = totalSupply();
        require(msg.value >= priceWL * qty, "Sorry, not enough amount sent!"); 
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verify(leaf, proof, false), "Sorry, you are not listed for whitelist");
        require(mintedWL[msg.sender] < maxPerWalletWL, "Sorry, you already own the max allowed");
        require(qty <= maxPerTx, "Sorry, too many per transaction");

        mintedWL[msg.sender] += qty;
        _safeMint(msg.sender, qty);
        emit Minted(msg.sender);
    }

    function mintPublic(uint256 qty) external payable nonReentrant{
        require(!paused, "Minting is paused");
        require(saleStatus == 2, 'Public sale not active');
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        require(qty <= maxPerTx, "Sorry, too many per transaction");
        require(msg.value >= pricePublic * qty, "Sorry, not enough amount sent!"); 
        
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
    
    function getPricePublic() public view returns (uint256){
        return pricePublic;
    }
    
    function getPriceWL() public view returns (uint256){
        return priceWL;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isRevealed == false) {
            return uriNotRevealed;
        }
        string memory base = baseURI;
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
    }

    

    // ADMIN FUNCTIONS
    
    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    function setMerkleRootFree(bytes32 _merkleRoot) public onlyOwner {
        merkleRootFree = _merkleRoot;
    }

    function setMerkleRootWL(bytes32 _merkleRoot) public onlyOwner {
        merkleRootWL = _merkleRoot;
    }

    function setSaleStatus(uint256 _saleStatus) public onlyOwner {
        saleStatus = _saleStatus;
    }

    // close minting forever!
    function closeMinting() public onlyOwner {
        uint256 supply = totalSupply();
        maxSupply = supply;
    }
    
    function flipRevealed(string memory _URI) public onlyOwner {
        baseURI = _URI;
        isRevealed = !isRevealed;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function setUriNotRevealed(string memory _URI) public onlyOwner {
        uriNotRevealed = _URI;
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

    function changeFree(uint256 _free) public onlyOwner {
        qtyFree = _free;
    }

    function setProvenanceHash(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function withdraw() onlyOwner public {
        uint256 balance = address(this).balance;
        require(payable(0x3E33f56c2308484696896aEa4d58AC493C2C2434).send((balance * 9200) / 10000));
        require(payable(0xe7e085E4A469AC08b12c1231f5C37410d9B12bFd).send((balance * 800) / 10000));
    }
    
    receive() external payable {}
    
}