// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract Vibewell is ERC721A, Ownable {

    using Strings for uint256;

    mapping (address => uint256) private mintedWL;

    uint256 public maxSupply = 3789;
    uint256 private pricePublic = 0.07 ether;
    uint256 public maxPerTxPublic = 10;
    uint256 public maxPerWL = 10;

    string private baseURI = "";
    string public provenance = "";
    string public uriNotRevealed = "";
    
    bool public paused = true;
    bool public isRevealed;
    
    
    event Minted(address caller);

    constructor() ERC721A("Vibewell", "VIBE") {}
    
    function saleMint(uint256 count, address to) external payable{
        require(!paused, "Minting is paused");
        uint256 supply = totalSupply();
        require(supply + count <= maxSupply, "Sorry, not enough left!");
        require(count <= maxPerTxPublic, "Sorry, too many per transaction");
        require(msg.value >= pricePublic * count, "Sorry, not enough amount sent!"); 
        
        _safeMint(to, count);

        emit Minted(to);
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

    function setPricePublic(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }

    function setMaxPerTx(uint256 _newMax) public onlyOwner {
        maxPerTxPublic = _newMax;
    }

    function setProvenanceHash(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(0x8d3C50D90f6Fa0B1a66274055Bb225d9df5666e7).send(balance));
    }


    receive() external payable {}
    
}