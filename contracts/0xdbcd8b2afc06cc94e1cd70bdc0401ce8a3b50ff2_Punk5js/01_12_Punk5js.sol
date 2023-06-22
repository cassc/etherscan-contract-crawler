// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Punk5js is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 10000;
    uint256 public cost = 69 ether;
    uint256 public maxPerWallet = 11;
    uint256 public maxFreePerWallet = 1;
    uint256 public maxMintAmountPerTx = 11;
    string public baseURI = "ipfs://bafybeicbexg2yufco4vo634efz2gugyokcj7fsyot4rqv7ys3waa64qyly/";
    string public extensionURI = ".json";
    bool public paused = true;
    mapping(address => bool) freeMint;
    
    constructor( ) ERC721A("Punk5js", "PUNK5JS") {
        _safeMint(_msgSender(), 100);
    }

    function publicMint(uint256 quantity) external payable {
        require(!paused, "The mint is not open!");
        require(quantity > 0 && quantity <= maxMintAmountPerTx, "Invalid mint quantity");
        require(_numberMinted(msg.sender) + quantity <= maxPerWallet, "Max per wallet exceeded");
        require(totalSupply() + quantity < maxSupply + 1, "Max supply exceeded");
        require(tx.origin == msg.sender);
            
        if(freeMint[_msgSender()]) {
            require(msg.value >= quantity * cost, 'Insufficient ETH Sent!');
        }
        else {
            require(msg.value >= (quantity - maxFreePerWallet) * cost, 'Insufficient ETH Sent!');
            freeMint[_msgSender()] = true;
        }

        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity)
        public
        payable
        onlyOwner
    {
        _safeMint(_msgSender(), quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), extensionURI));

    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setExtensionURI(string memory extension) public onlyOwner {
        extensionURI = extension;
    }


    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}