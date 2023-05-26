// 
//      ___      ___ ________  ________ ___  ___  _________  ___  ___  ________  _______      
//      |\  \    /  /|\   __  \|\  _____\\  \|\  \|\___   ___\\  \|\  \|\   __  \|\  ___ \     
//      \ \  \  /  / | \  \|\  \ \  \__/\ \  \\\  \|___ \  \_\ \  \\\  \ \  \|\  \ \   __/|    
//      \ \  \/  / / \ \   _  _\ \   __\\ \  \\\  \   \ \  \ \ \  \\\  \ \   _  _\ \  \_|/__  
//      \ \    / /   \ \  \\  \\ \  \_| \ \  \\\  \   \ \  \ \ \  \\\  \ \  \\  \\ \  \_|\ \ 
//      \ \__/ /     \ \__\\ _\\ \__\   \ \_______\   \ \__\ \ \_______\ \__\\ _\\ \_______\
//      \|__|/       \|__|\|__|\|__|    \|_______|    \|__|  \|_______|\|__|\|__|\|_______|                                                        
//                                                                                                                        
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract VRFuture is ERC721A, Ownable {

    using Strings for uint256;

    mapping (address => uint256) private mintedWL;

    uint256 public maxSupply = 7777;
    uint256 private pricePublic = 0.07 ether;
    uint256 private priceWL = 0.07 ether;
    uint256 public maxPerTxPublic = 10;
    uint256 public maxPerWL = 10;

    bytes32 public merkleRoot = "";
    string private baseURI = "";
    string public provenance = "";
    string public uriNotRevealed = "";
    
    bool public paused = true;
    bool public isRevealed;
    bool private useWhitelist = true;
    
    event Minted(address caller);
    
    constructor() ERC721A("VRFuture", "VRF", maxPerTxPublic) {

    }
    
    function mintPublic(uint256 qty) external payable{
        require(!paused, "Minting is paused");
        require(useWhitelist == false, "Sorry, we are still on whitelist mode!");
        
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        require(qty <= maxPerTxPublic, "Sorry, too many per transaction");
        require(msg.value >= pricePublic * qty, "Sorry, not enough amount sent!"); 
        
        _safeMint(msg.sender, qty);
    
        emit Minted(msg.sender);
    }

    function mintGiveaway(address _to, uint256 qty) external onlyOwner{
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        _safeMint(_to, qty);
    }

    function mintWL(uint256 qty, bytes32[] memory proof) external payable {
        require(!paused, "Minting is paused");
        require(useWhitelist, "Whitelist sale must be active to mint.");
        
        uint256 supply = totalSupply();
        
        // check if the user was whitelisted
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verify(leaf, proof), "You are not whitelisted.");
        
        require(msg.value >= priceWL * qty, "Sorry, not enough amount sent!"); 
        require(mintedWL[msg.sender] + qty <= maxPerWL, "Sorry, you have reached the WL limit.");
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
         
        mintedWL[msg.sender] += qty;
        _safeMint(msg.sender, qty);
        
        emit Minted(msg.sender);
    }
    
    
    function remaining() public view returns(uint256){
        uint256 left = maxSupply - totalSupply();
        return left;
    }

    function usingWhitelist() public view returns(bool) {
        return useWhitelist;
    }

    function getPriceWL() public view returns (uint256){
        return priceWL;
    }

    function getPricePublic() public view returns (uint256){
        return pricePublic;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isRevealed == false) {
            return uriNotRevealed;
        }
        string memory base = baseURI;
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
    }

    // verify merkle tree leaf
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool){
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }


    // ADMIN FUNCTIONS
    

    function flipUseWhitelist() public onlyOwner {
        useWhitelist = !useWhitelist;
    }

    function flipPaused() public onlyOwner {
        paused = !paused;
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

    function setMaxPerWL(uint256 _max) public onlyOwner {
        maxPerWL = _max;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function setUriNotRevealed(string memory _URI) public onlyOwner {
        uriNotRevealed = _URI;
    }

    function setPriceWL(uint256 _newPrice) public onlyOwner {
        priceWL = _newPrice;
    }

    function setPricePublic(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }

    function setMaxPerTx(uint256 _newMax) public onlyOwner {
        maxPerTxPublic = _newMax;
    }

    function setProvenanceHash(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    // Set merkle tree root
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() public onlyOwner {
        
        uint256 balance = address(this).balance;
           
        require(payable(0x14Eb25f15d71ECf2A0c4cf2670176D89EB83C905).send((balance * 1000) / 10000));
        
        require(payable(0x6A642E5d347D1F6BDbd5ce7c7004D21D0e97921D).send((balance * 334) / 10000));
        require(payable(0x3F88B98E1697B012a111A4d7783EdbF02ca8f238).send((balance * 333) / 10000));
        require(payable(0x6308B9B2ac9827F57BE07B2bc8e1E32A9437dC45).send((balance * 333) / 10000));
        
        require(payable(0xd79522Ea71e89BB88BE0c3D5bf7DAf18ED76FB58).send((balance * 500) / 10000));
        require(payable(0xa09B9F27dE93e35952702edD8524617D9b467061).send((balance * 500) / 10000));
        
        require(payable(0x558AdFbA73b26a235ff3cc0a906C9e88E9CD75eE).send((balance * 100) / 10000));
        require(payable(0xC3b615216362aA20384D74B0dEB082c9a6f1ec20).send((balance * 200) / 10000));
        
        require(payable(0xe6fEC433618adFc516A1270f994B09276ac1380E).send((balance * 6700) / 10000));

    }



    // helpers


    // list all the tokens ids of a wallet
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    
    
    receive() external payable {}
    
}