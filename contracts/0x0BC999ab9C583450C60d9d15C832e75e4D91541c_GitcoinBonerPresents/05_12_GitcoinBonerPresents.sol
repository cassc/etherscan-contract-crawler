// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GitcoinBonerPresents is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 2000;
    uint256 public cost = 0.003 ether;
    uint256 public maxPerWallet = 10;
    uint256 public maxFreePerWallet = 0;
    uint256 public maxMintAmountPerTx = 5;
    string public baseURI;
    bool public paused = true;
    
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721A(_tokenName, _tokenSymbol) {}

    modifier mintCheck(uint256 quantity) {
        require(quantity > 0 && quantity <= maxMintAmountPerTx, "Invalid mint amount!");
        require(_numberMinted(msg.sender) + quantity <= maxPerWallet, "Max per wallet mint exceeded");
        require(totalSupply() + quantity < maxSupply + 1, "Max supply exceeded");
        _;
    }

    modifier mintPriceCheck(uint256 quantity) {
        uint256 realCost = 0;
        if (_numberMinted(msg.sender) < maxFreePerWallet) {
            uint256 freeMintsLeft = maxFreePerWallet - _numberMinted(msg.sender);
            // 0 or 1
            realCost = cost * freeMintsLeft;
        }
        require(msg.value >= cost * quantity - realCost, "Please send the exact amount.");
        _;
    }

    function mint(uint256 quantity) external payable mintCheck(quantity) mintPriceCheck(quantity) {
        require(!paused, "The contract is paused!");
        _safeMint(msg.sender, quantity);
    }

    function premint(uint256 quantity)
        public
        payable
        mintCheck(quantity)
        onlyOwner
    {
        _safeMint(_msgSender(), quantity);
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));

    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}