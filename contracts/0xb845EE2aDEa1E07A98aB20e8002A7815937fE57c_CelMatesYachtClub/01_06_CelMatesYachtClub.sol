// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CelMatesYachtClub is ERC721A, Ownable {
    using Strings for uint256;
    string  public baseURI;
    uint256 public constant maxSupply         = 6969;
    uint256 public constant maxFree           = 3;
    uint256 public price                      = 0.0169 ether;
    uint256 public maxPerTx                   = 15;
    uint256 public maxPerWallet               = 30;
    uint256 public totalFree                  = 500;
    uint256 public freeMintCount              = 0;
    bool    public mintEnabled                = false;
    bool    public revealed                   = false;

    mapping(address => uint256) public _freeMints;
    mapping(address => uint256) public _walletMints;

    address public constant w1 = 0x6bA37Efa24472E27DD1513199b2A0e3ccE7A4f09;
    address public constant w2 = 0x7A7DF9264554d71efA5310B1fFE1b971A25f8d53;
    address public constant w3 = 0x1D9D847B7952F780Ae74b7ee62E0b6CAb6794a77;
    address public constant w4 = 0x88375f4c4Dfe2f40154e76C3175DE7ceD551Dd33;
    address public constant w5 = 0x70484ec10105b62762D7C2D4A84B60f0A34B7Caf;

    constructor() ERC721A("Cel Mates Yacht Club", "CMYC"){}

    function mint(uint256 amount) external payable {
        require(mintEnabled, "Mint is not live yet");
        require(totalSupply() + amount <= maxSupply, "Cels full");
        require(amount <= maxPerTx, "Too many per tx");
        require(_walletMints[msg.sender] + amount <= maxPerWallet, "Too many per wallet");
        require(msg.sender == tx.origin, "No contracts");
        uint256 cost = price;
        uint256 freeLeft = maxFree - _freeMints[msg.sender];
        bool isFree = ((freeMintCount + freeLeft <= totalFree) && (_freeMints[msg.sender] < maxFree));

        if (isFree) { 
            if(amount >= freeLeft) {
                uint256 paid = amount - freeLeft;
                require(msg.value >= (paid * cost), "Not enough ETH");
                _freeMints[msg.sender] = maxFree;
                freeMintCount += freeLeft;
            } else if (amount < freeLeft) {
                require(msg.value >= 0, "Not enough ETH");
                _freeMints[msg.sender] += amount;
                freeMintCount += amount;
            }
        } else {
            require(msg.value >= amount * cost, "Not enough ETH");
        }
        
        _walletMints[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        if (!revealed) {
            return "https://www.celmatesyc.wtf/prereveal.json";
        }
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }
    
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory baseuri_) public onlyOwner {
        baseURI = baseuri_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxTotalFree(uint256 MaxTotalFree_) external onlyOwner {
        totalFree = MaxTotalFree_;
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function reserve(uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= maxSupply, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one");
        require(_walletMints[_msgSender()] + tokens <= 69, "Can only reserve 69 tokens");

        _walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(w1, ((balance * 20) / 100));
        _withdraw(w2, ((balance * 20) / 100));
        _withdraw(w3, ((balance * 20) / 100));
        _withdraw(w4, ((balance * 20) / 100));
        _withdraw(w5, ((balance * 20) / 100));
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}