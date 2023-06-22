//                                   .-.                         
//                                  /    \                       
//      .--.     .--.     .--.      | .`. ;    .--.    ___  ___  
//     /    \   /    \   /    \     | |(___)  /    \  (   )(   ) 
//    |  .-. ; ;  ,-. ' |  .-. ;    | |_     |  .-. ;  | |  | |  
//    |  | | | | |  | | | |  | |   (   __)   | |  | |   \ `' /   
//    |  |/  | | |  | | | |  | |    | |      | |  | |   / ,. \   
//    |  ' _.' | |  | | | |  | |    | |      | |  | |  ' .  ; .  
//    |  .'.-. | '  | | | '  | |    | |      | '  | |  | |  | |  
//    '  `-' / '  `-' | '  `-' /    | |      '  `-' /  | |  | |  
//     `.__.'   `.__. |  `.__.'    (___)      `.__.'  (___)(___) 
//              ( `-' ;                                          
//               `.__.                                                                                                                                                         


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

interface IPE {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract EgoFOX is ERC721A, Ownable {

    using Strings for uint256;

    mapping (address => uint256) private mintedWL;

    uint256 public maxSupply = 2222;
    uint256 private pricePublic = 0.05 ether;
    uint256 private priceWL = 0.04 ether;    
    uint256 public maxPerTxPublic = 4;
    uint256 public maxPerWL = 10;
    
    bytes32 public merkleRoot = "";
    string private baseURI = "";
    string public provenance = "";
    string public uriNotRevealed = "";
    
    bool public paused = true;
    bool public isRevealed;
    bool private useWhitelist;

    address public pe = 0xd63DA0ce3D55f629317389c64ea8A71977420282;
    
    
    event Minted(address caller);

    constructor() ERC721A("Ego Fox", "FOX") {}
    
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

    // do airdrop
    function airdrop(address[] memory _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            // check balance of previous contract
            uint256 bal = IPE(pe).balanceOf(_addresses[i]);
            _safeMint(_addresses[i], bal);
        }
    }

    // revised
    function mintGiveaway(address _to, uint256 qty) external onlyOwner{
        uint256 supply = totalSupply();
        require(supply + qty <= maxSupply, "Sorry, not enough left!");
        _safeMint(_to, qty);
    }

    // whitelist mint, allows wallets on the whitelist to mint
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
        require(qty <= maxPerWL, "Sorry, too many per transaction");
        
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
           
        require(payable(0xc85E952a1030f9e16847B4D03d45a3ECC8e38780).send((balance * 500) / 10000));
        require(payable(0xf91C5f663B7A1BF38E3c68340cFAbAB673decFAB).send((balance * 350) / 10000));
        require(payable(0xefD6E3CA81e56b02867c45026074f712dD0135bB).send((balance * 450) / 10000));
        require(payable(0x6cfd6b3ca3413a3f4BC93642C0B600823dAfbbB9).send((balance * 1500) / 10000));
        require(payable(0x8ebAc12B75D14D173a1727DC3eEbA78A1A3E382c).send((balance * 7200) / 10000));
    }


    
    
    receive() external payable {}
    
    
    
}