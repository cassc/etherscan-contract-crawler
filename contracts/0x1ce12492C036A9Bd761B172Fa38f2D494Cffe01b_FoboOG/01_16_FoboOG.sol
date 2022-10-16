// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721psi/contracts/ERC721Psi.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FoboOG is ERC721Psi,Ownable {

    uint public whiteMintPrice = 0 ether;
    uint public mintPrice = 0.1 ether;
    uint constant public maxSupply = 7777;
    bool public publicMintSwitch = false;
    string baseURI;

    bytes32 public merkleRoot;
    mapping( address => bool ) whiteListMinted;

    constructor() 
        ERC721Psi ("Fobo OG Pass", "FOG"){
    }

    function switchPublicMint() public onlyOwner {
        publicMintSwitch = !publicMintSwitch;
    }

    function setWhiteMintPrice(uint _price) public onlyOwner {
        whiteMintPrice = _price;
    }

    function setMintPrice(uint price) public onlyOwner{
        mintPrice = price;
    }


    function setBaseURI(string calldata baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /**
     * Mint to partners
     */
    function premint(address to,uint quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

    /**
     * Mint to Whitelist, but each address can only mint once
     */
    function whiteListMint(bytes32[] calldata proof,uint amount) external payable{
        require(MerkleProof.verifyCalldata(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender,amount))),"Fobo OG: Invalid proof");
        require(!whiteListMinted[msg.sender],"Fobo OG: Already minted");
        require(msg.value == whiteMintPrice,"Fobo OG: Insufficient amount");
        whiteListMinted[msg.sender] = true;
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint quantity) external payable {
        require(publicMintSwitch,"Fobo OG: Public mint is not open"); 
        require(totalSupply() + quantity <= maxSupply,"Fobo OG: Exceed max supply");
        require(msg.value == mintPrice * quantity,"Fobo OG: Insufficient amount");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}