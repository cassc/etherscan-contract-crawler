pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PaymentSplitter.sol"; 

contract TheBabySaudis is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {

    string public        baseURI;
    uint public          price             = 0 ether;
    uint public          maxPerTx          = 2;
    uint public          maxPerWallet      = 2;
    uint public          maxSupply         = 5555;
    uint public          reservedSupply    = 150;
    bool public          mintEnabled       = false;
    bool public          teamClaimed       = false;

    address[] private _payees = [
        0x2CE39D3C0f810c5Db135613008A3599105C4FBFd,
        0xe6e9557c6ECA408D525F141d7E6616320390D636,
        0xAe76f01841e85b47FD970BEB93120C4e3DD85643
    ];

    uint256[] private _shares = [
        33,
        33,
        34
    ];

    constructor() 
    ERC721A("TheBabySaudis", "BSAUDI")
    PaymentSplitter(_payees, _shares) {}

    function mint(uint256 amt) external    
    {
        require(mintEnabled, "Minting is not live yet");
        require( amt < maxPerTx + 1, "Max per TX reached.");
        require(_numberMinted(_msgSender()) < maxPerWallet, "Don't be greedy");
        require(totalSupply() + amt < maxSupply + 1, "Max supply reached");

        _safeMint(msg.sender, amt);
    }

    function enableMint()  external onlyOwner {
        mintEnabled = true;
    }

    function teamClaim() external {
        require(teamClaimed == false);

        _safeMint(_payees[0], 50);
        _safeMint(_payees[1], 50);
        _safeMint(_payees[2], 50);

        teamClaimed = true;
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setmaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external nonReentrant {
        release(payable(_payees[0]));
        release(payable(_payees[1]));
        release(payable(_payees[2]));
    }
}