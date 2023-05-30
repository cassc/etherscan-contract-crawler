// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GeishaTeahouse is ERC721Enumerable, ERC721Pausable, Ownable, ERC721Burnable {
    bool public revealed = false;
    string private baseURI;
    uint256 public preSaleCost = 0.0555 ether;
    uint256 public cost = 0.0888 ether;
    uint256 public maxSupply = 9999;
    uint256 public maxMintWhitelist = 5;
    uint256 public maxMintAmount = 7;
    enum Sale{NONE, WHITELIST, SALE}
    Sale public sale;
    bytes32 public root;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    function setSale(Sale _sale) public onlyOwner {
        sale = _sale;
    }

    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable whenNotPaused {
        uint256 supply = totalSupply();
        uint256 actualCost = (sale == Sale.WHITELIST) ? preSaleCost : cost;
        require(_mintAmount > 0, "mint amount > 0");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        if (msg.sender != owner()) {
            require(sale != Sale.NONE, "Sale has not started yet");
            require(_mintAmount <= maxMintAmount, "Too many items minted");
            if (sale == Sale.WHITELIST) {
                bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
                require(MerkleProof.verify(_merkleProof, root, _leaf), "invalid proof");
                uint256 ownerMintedCount = balanceOf(msg.sender);
                require(
                    ownerMintedCount + _mintAmount <= maxMintWhitelist,
                    "max mint amount exceeded"
                );
            }
            require(msg.value >= actualCost * _mintAmount, "insufficient funds");
        }
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function airdrop(uint256 _mintAmount, address destination) public onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "mint amount > 0");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(destination, supply + i);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        if (!revealed) {
            return baseURI;
        } else {
            string memory uri = super.tokenURI(tokenId);
            return uri;
        }
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function setReveal(bool _reveal) public onlyOwner {
        revealed = _reveal;
    }

    function setPaused(bool _state) public onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setMaxMintWhitelist(uint256 _amount) public onlyOwner {
        maxMintWhitelist = _amount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function withdraw() public payable onlyOwner {
        (bool so,) = payable(msg.sender).call{value : address(this).balance}("");
        require(so, "WITHDRAW ERROR");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Enumerable, ERC721Pausable, ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}