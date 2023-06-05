// SPDX-License-Identifier: MIT

// • ▌ ▄ ·.              ▐ ▄  ▄▄▄·  ▄▄▄·▄▄▄ .·▄▄▄▄•
// ·██ ▐███▪▪     ▪     •█▌▐█▐█ ▀█ ▐█ ▄█▀▄.▀·▪▀·.█▌
// ▐█ ▌▐▌▐█· ▄█▀▄  ▄█▀▄ ▐█▐▐▌▄█▀▀█  ██▀·▐▀▀▪▄▄█▀▀▀•
// ██ ██▌▐█▌▐█▌.▐▌▐█▌.▐▌██▐█▌▐█ ▪▐▌▐█▪·•▐█▄▄▌█▌▪▄█▀
// ▀▀  █▪▀▀▀ ▀█▄▀▪ ▀█▄▀▪▀▀ █▪ ▀  ▀ .▀    ▀▀▀ ·▀▀▀ •

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract Moonapez is ERC721A, Ownable, ReentrancyGuard {
    
    uint256 public MINT_PRICE = 0.003 ether;
    uint256 public MAX_SUPPLY = 8000;
    uint256 public MAX_FREE_SUPPLY = 4000;
    uint256 public MAX_FREE_PER_WALLET = 2;
    uint256 public MAX_PUBLIC_PER_WALLET = 10;

    using Strings for uint256;
    string public baseURI;
    mapping(address => uint256) public addressFreeMintedBalance;

    constructor(string memory initBaseURI) ERC721A("Moonapez", "MA") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function freeMint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();
        uint256 addressFreeMintedCount = addressFreeMintedBalance[msg.sender];
        require(
            addressFreeMintedCount + _mintAmount <= MAX_FREE_PER_WALLET,
            "Max Moonapez per address exceeded"
        );
        require(_mintAmount > 0, "Cannot mint 0 Moonapez");
        require(
            s + _mintAmount <= MAX_FREE_SUPPLY,
            "Cannot exceed Moonapez supply"
        );
        for (uint256 i = 0; i < _mintAmount; ++i) {
            addressFreeMintedBalance[msg.sender]++;
        }
        _safeMint(msg.sender, _mintAmount);
        delete s;
        delete addressFreeMintedCount;
    }

    function mint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();
        require(_mintAmount > 0, "Cant mint 0 Moonapez");
        require(
            _mintAmount <= MAX_PUBLIC_PER_WALLET,
            "Cant mint more Moonapez"
        );
        require(s + _mintAmount <= MAX_SUPPLY, "Cant exceed Moonapez supply");
        require(msg.value >= MINT_PRICE * _mintAmount);
        _safeMint(msg.sender, _mintAmount);
        delete s;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
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

    function setPrice(uint256 _newPrice) public onlyOwner {
        MINT_PRICE = _newPrice;
    }

    function setMaxFreeSupply(uint256 _newMaxFreeSupply) public onlyOwner {
        MAX_FREE_SUPPLY = _newMaxFreeSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxPublicMintAmountPerWallet(uint256 _amount) public onlyOwner {
        MAX_PUBLIC_PER_WALLET = _amount;
    }

    function setFreeMintAmountPerWallet(uint256 _amount) public onlyOwner {
        MAX_FREE_PER_WALLET = _amount;
    }

    function teamMint(uint256 _number) external onlyOwner {
        _safeMint(_msgSender(), _number);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}