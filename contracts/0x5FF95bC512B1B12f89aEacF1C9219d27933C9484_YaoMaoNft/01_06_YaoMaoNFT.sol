// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Modified by @YaoMaoNft for 
// the project YaoMao 
// www.yaomaonft.xyz

contract YaoMaoNft is ERC721A, Ownable {

    using Strings for uint256;

    // Paid tokens per transaction
    uint256 public constant MAX_PAID_PER_TX = 5;
    // Free tokens per transaction
    uint256 public constant MAX_FREE_PER_TX = 2;
    // Paid tokens per wallet 
    uint256 public constant MAX_PAID_PER_WALLET = 5;
    // Free tokens per wallet
    uint256 public constant MAX_FREE_PER_WALLET = 2;
    // Maximum supply
    uint256 public constant MAX_SUPPLY = 999;
    // Owner tokens per mint
    uint256 public constant MAX_DEV_MINT = 1;
    // The minting price for non-free tokens.
    uint256 public constant MINT_PRICE = 0.0069 ether;
    // The total number of free tokens.
    uint256 public constant MAX_FREE = 666;
    uint256 public numFreeMinted;
    string public baseURI;
    bool public isSaleActive = false;
    mapping(address => uint) public freeMintClaimed;
    mapping(address => uint) public numPaidMinted;

    constructor(string memory _baseUri) ERC721A("YaoMaoNft", "YMN") {
        baseURI = _baseUri;
    }

    function mint(uint8 _quantity) external payable {
        uint256 currentSupply = totalSupply();

        require(tx.origin == msg.sender, "Origin doesn't match caller.");
        
        require (isSaleActive, "The sale has not started yet.");

        require(currentSupply + _quantity <= MAX_SUPPLY, "Quantity exceeded maximum supply limit.");

        require(_quantity > 0, "Quantity must be greater than 0.");

        require(_quantity <= MAX_PAID_PER_TX, "Quantity must not exceed maximum tokens per tx.");
        
        require(msg.value >= MINT_PRICE * _quantity, "Invalid value sent. ");

        require(numPaidMinted[msg.sender] + _quantity <= MAX_PAID_PER_WALLET, "Quantity exceeds max tokens per wallet.");

        numPaidMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function freeMint(uint8 _quantity) external payable {
        uint256 currentSupply = totalSupply();

        require(tx.origin == msg.sender, "Origin doesn't match caller.");

        require(isSaleActive, "The sale has not started yet.");

        require(currentSupply + _quantity <= MAX_SUPPLY, "Quantity exceeds max supply limit.");

        require(_quantity > 0, "Quantity must be greater than 0.");

        require(_quantity <= MAX_FREE_PER_TX, "Quantity exceeds max limit per tx.");
        
        require(freeMintClaimed[msg.sender] + _quantity <= MAX_FREE_PER_WALLET, "Quantity exceeds max free tokens per wallet.");
        
        require(numFreeMinted <= MAX_FREE, "No free tokens remain.");

        freeMintClaimed[msg.sender] += _quantity;
        numFreeMinted += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function ownerMint(address _address, uint256 _quantity) external onlyOwner {
        uint256 currentSupply = totalSupply();

        require(currentSupply + _quantity <= MAX_SUPPLY, "Quantity exceeds max supply.");

        require(_quantity <= MAX_DEV_MINT, "Quantity exceeds max per minting.");

        _safeMint(_address, _quantity);
    }

    function setIsSaleActive(bool _state) external onlyOwner {
        isSaleActive = _state;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

     function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }
}