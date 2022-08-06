// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract FindingDodo is Ownable, ERC721A {
    enum SaleStatus {
        Inactive,
        EMA,
        Public,
        Completed
    }

    uint256 public WHITELIST_SPOTS = 1000;
    uint256 public MAX_DODOS = 10000;
    uint256 public MAX_MINT = 10;
    uint256 public WL_MINT = 5;

    uint256 public whitelistPrice = 0.06 ether;
    uint256 public publicPrice = 0.07 ether;

    uint256 public TREASURY_MINT = 0;

    SaleStatus public saleStatus;

    mapping(address => uint256) public whitelistMints;

    // Will set this later
    string private _baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmTRuhHEba6fgCzvCX4PRxMAMh1zU5szpM6xAbhEdJNP63/";

    modifier noContracts() {
        require(msg.sender == tx.origin);
        _;
    }

    constructor() ERC721A("FindingDodo", "FD") {}

    // Public Mint Mechanism

    function publicMint(uint256 _mints) external payable noContracts {
        require(saleStatus == SaleStatus.Public, "FD: Public mint isn't active");
        require(_mints < MAX_MINT + 1, "FD: Exceeds Max per TXN");
        require(totalSupply() + _mints <= MAX_DODOS, "FD: Exceeds Max Allocation");
        require(msg.value == publicPrice * _mints, "FD: Insufficient funds");
        _mint(msg.sender, _mints);
    }

    // Whitelist Mint Mechanism

    function whitelistMint(uint256 _mints) external payable noContracts {
        require(saleStatus == SaleStatus.EMA, "FD: Whitelist mint isn't active");
        require(_mints < WL_MINT + 1, "FD: Exceeds Max per TXN for WL");
        require(totalSupply() + _mints <= MAX_DODOS, "FD: Exceeds Max Supply");
        require(totalSupply() + _mints <= WHITELIST_SPOTS + TREASURY_MINT, "FD: Exceeds Max Allocation");
        require(msg.value == _mints * whitelistPrice, "FD: Insufficient funds");
        // require(whitelistMints[msg.sender] >=  _mints, "FD: No WL allocation left");

        // whitelistMints[msg.sender] -= _mints;
        
        _mint(msg.sender, _mints);
    }

    // Owner functions

    function whitelistAddresses(address[] memory users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            whitelistMints[users[i]] = WL_MINT;
        }
    }
    
    function treasuryMint(uint256 _amount, address _mintAddress) external onlyOwner {
        require(totalSupply() + _amount <= MAX_DODOS, "FD: Cannot mint more than total supply");
        TREASURY_MINT += _amount;
        _safeMint(_mintAddress, _amount);
    }

    function setSalePrice(uint256 _publicPrice, uint256 _whitelistPrice) external onlyOwner {
        publicPrice = _publicPrice;
        whitelistPrice = _whitelistPrice;
    }

    function setStatus(SaleStatus _newStatus) external onlyOwner {
        saleStatus = _newStatus;
    }

    function withdrawAll(address _wallet) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_wallet).transfer(balance);
    }

    function setWLMints(uint256 _mints) external onlyOwner {
        WL_MINT = _mints;
    }

    // Base URI standard functions
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setWLSpots(uint256 _wlspots) external onlyOwner {
        WHITELIST_SPOTS = _wlspots;
    }
}