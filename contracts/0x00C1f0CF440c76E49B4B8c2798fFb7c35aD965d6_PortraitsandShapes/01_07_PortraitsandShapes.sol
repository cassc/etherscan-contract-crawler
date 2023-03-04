// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";


contract PortraitsandShapes is ERC721A, Ownable {
    using Strings for uint256;
        
    uint256 public PRESALE_PRICE = 0.001 ether;
    uint256 public PUBLIC_PRICE = 0.01 ether;
    
    uint256 public MAX_PER_TX = 2000;
    uint256 public MAX_PER_WALLET = 3;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public RESERVED = 333;

    bool public presaleOpen = false;
    bool public publicSaleOpen = false;
    
    string public baseExtension = '.json';
    string private _baseTokenURI;
    string public placeholderTokenUri;
    bool public isRevealed;
 
    bytes32 public merkleRoot;

    mapping(address => uint256) public _owners;

    constructor() ERC721A("Portraits and Shapes by Steven Wilson", "PORT") {}

    function whitelistMint(uint256 quantity, bytes32[] memory _merkleProof) external payable {
        require(presaleOpen, "Pre-sale is not open");
        require(quantity > 0, "quantity of tokens cannot be less than or equal to 0");
        require(quantity <= MAX_PER_WALLET - _owners[msg.sender], "exceeded max per wallet");
        require(totalSupply() + quantity <= MAX_SUPPLY - RESERVED, "exceed max supply of tokens");
        require(msg.value >= PRESALE_PRICE * quantity, "insufficient ether value");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Incorrect proof");
        
        _owners[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable {
        require(publicSaleOpen, "Public Sale is not open");
        require(quantity > 0, "quantity of tokens cannot be less than or equal to 0");
        require(quantity <= MAX_PER_TX, "exceed max per transaction");
        require(quantity <= MAX_PER_WALLET - _owners[msg.sender], "exceeded max per wallet");
        require(totalSupply() + quantity <= MAX_SUPPLY - RESERVED, "exceed max supply of tokens");
        require(msg.value >= PUBLIC_PRICE * quantity, "insufficient ether value");

        _owners[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }


    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

        if(!isRevealed) {
            return placeholderTokenUri;
        }

        string memory base = _baseURI();
        require(bytes(base).length > 0, "baseURI not set");
        return string(abi.encodePacked(base, tokenID.toString(), baseExtension));
    }

    
    function isWhitelist(bytes32[] memory _merkleProof) public view returns (bool) {
       bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
       return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /* *************** */
    /* OWNER FUNCTIONS */
    /* *************** */
    function giveAway(address to, uint256 quantity) external onlyOwner {
        require(quantity <= RESERVED);
        RESERVED -= quantity;
        _safeMint(to, quantity);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function setBaseExtension(string memory _newExtension) public onlyOwner {
        baseExtension = _newExtension;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function updateMaxPerTX(uint256 newLimit) external onlyOwner {
        MAX_PER_TX = newLimit;
    }

    function updateMaxPerWallet(uint256 newLimit) external onlyOwner {
        MAX_PER_WALLET = newLimit;
    }

    function startPresale() external onlyOwner {
        presaleOpen = true;
        publicSaleOpen = false;
    }

    function startPublicSale() external onlyOwner {
        publicSaleOpen = true;
        presaleOpen = false;
    }

    function changePresalePrice(uint256 price) external onlyOwner {
        PRESALE_PRICE = price;
    }

    function changePublicSalePrice(uint256 price) external onlyOwner {
        PUBLIC_PRICE = price;
    }

     function close(address payable _to) public onlyOwner {
         selfdestruct(_to);   
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }
}