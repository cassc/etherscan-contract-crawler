//SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MetaverseRiders is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string baseURI;
    
    uint256 public cost;
    uint256 public maxFreeMintsPerTx;
    uint256 public maxFreeSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public maxSupply;
    uint256 public maxPerWallet;

    string public baseExtension = ".json";
    bool public paused = true;

    mapping(address => uint256) private mintedFreeAmount;
    
    constructor(
        string memory _initBaseURI,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxFreeMintsPerTx,
        uint256 _maxFreeSupply,
        uint256 _maxMintAmountPerTx,
        uint256 _maxSupply,
        uint256 _maxPerWallet
    ) ERC721A(_tokenName, _tokenSymbol) { 
        setBaseURI(_initBaseURI);
        setPrice(_cost);
        setMaxFreePerTx(_maxFreeMintsPerTx);
        setMaxFreeSupply(_maxFreeSupply);
        setMaxPerTx(_maxMintAmountPerTx);
        setMaxPerWallet(_maxPerWallet);
        setMaxSupply(_maxSupply);
        _safeMint(msg.sender, 1);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        if (totalSupply() + _mintAmount < maxFreeSupply + 1) {
            mintedFreeAmount[msg.sender] += _mintAmount;
        }
        require(mintedFreeAmount[msg.sender] <= maxFreeMintsPerTx, "Exceeds free max per tx!");
        require(_numberMinted(msg.sender) + _mintAmount <= maxPerWallet, "Exceeds max wallet limits!");
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        uint256 price = cost;
        if (totalSupply() + _mintAmount < maxFreeSupply + 1) {
            price = 0;
        }
        require(msg.value >= price * _mintAmount, "Insufficient funds!");
        _;
    }

    function mint(uint256 _mintAmount) 
        public 
        payable 
        mintPriceCompliance(_mintAmount) 
        mintCompliance(_mintAmount) 
    {
        require(!paused, "The contract is paused!");
        _safeMint(_msgSender(), _mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setMaxFreePerTx(uint256 _maxFreeMintsPerTx) public onlyOwner {
        maxFreeMintsPerTx = _maxFreeMintsPerTx;
    }

    function setMaxFreeSupply(uint256 _maxFreeSupply) public onlyOwner {
        maxFreeSupply = _maxFreeSupply;
    }
    
    function setMaxPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function ownerAirdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function setPrice(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setPaused() public onlyOwner {
        paused = !paused;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }      
}