// SPDX-License-Identifier: MIT

//███╗   ██╗███████╗██╗  ██╗ ██████╗                          
//████╗  ██║██╔════╝██║ ██╔╝██╔═══██╗                         
//██╔██╗ ██║█████╗  █████╔╝ ██║   ██║                         
//██║╚██╗██║██╔══╝  ██╔═██╗ ██║   ██║                         
//██║ ╚████║███████╗██║  ██╗╚██████╔╝                         
//╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝                          
                                                            
//██████╗  █████╗ ██████╗ ██╗   ██╗███╗   ███╗ █████╗ ███████╗
//██╔══██╗██╔══██╗██╔══██╗██║   ██║████╗ ████║██╔══██╗██╔════╝
//██║  ██║███████║██████╔╝██║   ██║██╔████╔██║███████║███████╗
//██║  ██║██╔══██║██╔══██╗██║   ██║██║╚██╔╝██║██╔══██║╚════██║
//██████╔╝██║  ██║██║  ██║╚██████╔╝██║ ╚═╝ ██║██║  ██║███████║
//╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝
// By IlyaKazakov + Dtandre 

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NekoDarumas is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 5000;
    uint256 public constant MAX_MINT_TOKENS = 4990;
    uint256 public constant MAX_BATCH_MINT = 20;
    
    
    uint256 public price = 0.05 ether;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;

    mapping(address => uint256) private _presaleMints;
    uint256 public presaleMaxPerWallet = 5;

    string public baseURI;
    bytes32 public merkleRoot;

    constructor() ERC721A("Neko Darumas", "DARUMA") {}

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPresaleMaxPerWallet(uint256 _newPresaleMaxPerWallet) external onlyOwner {
        presaleMaxPerWallet = _newPresaleMaxPerWallet;
    }

    function mintPresale(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStarted, "Presale has not started");
        require(totalSupply() + tokens <= MAX_MINT_TOKENS, "Minting would exceed max allowed");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not eligible for the presale");
        require(_presaleMints[_msgSender()] + tokens <= presaleMaxPerWallet, "Presale limit for this wallet reached");
        require(tokens <= MAX_BATCH_MINT, "Cannot purchase this many tokens in a transaction"); 
        require(tokens > 0, "Must mint at least one token");
        require(price * tokens == msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
        _presaleMints[_msgSender()] += tokens;
    }

    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Public sale is not active");
        require(totalSupply() + tokens <= MAX_MINT_TOKENS, "Minting would exceed max allowed");
        require(tokens <= MAX_BATCH_MINT, "Cannot purchase this many tokens in a transaction");     
        require(tokens > 0, "Must mint at least one token");
        require(price * tokens == msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _safeMint(to, tokens);
    }

    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }



}