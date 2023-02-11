// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract A$$Pix is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    string public baseURI;
    string public notRevealedUri = "ipfs://bafybeicj552wzj7ukfgs7z7oapsivesyueu7hn54l7hqtuo6w76fokyds4/pre-reveal.json";
    string public baseExtension = ".json";
    uint256 public cost = 0.001 ether;
    uint256 public Freecost = 0 ether;
    uint256 public maxSupply = 4069;
    uint256 public maxMintAmountPaid = 9; 
    uint256 public maxMintAmountFREE = 1;

    mapping(address => uint256) public addressMintedBalance;

    bool public revealed = false;

    uint256 public currentState = 0;
  
    constructor() ERC721A("A$$Pix", "AP") {}

    /////////////////////////////
    // CORE FUNCTIONALITY
    /////////////////////////////

    function Mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(currentState > 0, "the contract is paused");
        require(supply + _mintAmount <= maxSupply, "Max Supply limit exceeded");
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
         if (ownerMintedCount == 0 ) {
            require(_mintAmount <= maxMintAmountFREE, "Max FREE mint amount per TRX exceeded" );
            require(ownerMintedCount + _mintAmount <= maxMintAmountFREE, "Max FREE NFT per address exceeded" );
            require(msg.value >= Freecost * _mintAmount, "Insufficient funds");
        } else if (ownerMintedCount >= 1 ) {
            require(_mintAmount <= maxMintAmountPaid + 1, "Max FREE mint amount per TRX exceeded" );
            require(ownerMintedCount + _mintAmount <= maxMintAmountPaid + 1, "Max NFT per address exceeded" );
            require(msg.value >= cost * _mintAmount, "Insufficient funds For mint");
        }

        addressMintedBalance[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }
	
    function TeamMint(uint256 _mintAmount, address _receiver) public onlyOwner {
	    require(_mintAmount > 0, "need to mint at least 1 NFT");
	    require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        _safeMint(_receiver, _mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
	
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
	
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token" );
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string( abi.encodePacked( currentBaseURI, tokenId.toString(), baseExtension ) ) : "";
    }

    /////////////////////////////
    // CONTRACT MANAGEMENT 
    /////////////////////////////

    function reveal() public onlyOwner {
        revealed = true;
    }
	
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setCost(uint256 _price) public onlyOwner {
        cost = _price;
    }

    function setFreecost(uint256 _price) public onlyOwner {
        Freecost = _price;
    }

    function pause() public onlyOwner {
        currentState = 0;
    }

    function setPublicMint() public onlyOwner {
        currentState = 1;
    }

    function setmaxMintAmountPaid(uint256 _newmaxMintAmountPaid) public onlyOwner {
        maxMintAmountPaid = _newmaxMintAmountPaid;
    }

    function setmaxMintAmountFREE(uint256 _newmaxMintAmountFREE) public onlyOwner {
        maxMintAmountFREE = _newmaxMintAmountFREE;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    /////////////////////////////
    // OPENSEA FILTER REGISTRY 
    /////////////////////////////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}