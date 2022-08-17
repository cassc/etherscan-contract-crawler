// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import './ERC721A.sol';

/**
 * @title Kodaz contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract Kodaz is Ownable, ERC721A {
    uint256 public constant maxSupply = 10000;
    uint256 public constant freeAmount = 500;
    uint256 public constant reserveAmount = 500;
    uint256 public constant maxFreeMintPerWallet = 3;

    uint256 public guaranteedMinAmount;
    uint256 public reservedAmount;

    bool public unlockFlag;    

    uint32 public saleStartTime = 0;
    uint256 public mintPrice = 0.01 ether;    
    uint256 public maxAmountPerMint = 10;    

    mapping (address => bool) public guaranteedWallets;
    mapping (address => bool) public guaranteedWalletMint;

    address private wallet1 = 0xED44447e2d312EF905D1167669E604067d0D91FA;
    address private wallet2 = 0xA5344090f9eb84B18564ab3e44b4637ceeB6Cd4c;
    address private wallet3 = 0x7A4AFBf4a877FF05b2C415Ab8EC457b08ED02793;
    address private wallet4 = 0xF5caf09F580c42AfebcF3125637e047F8126c61c;

    constructor() ERC721A("KODAZ", "KODAZ") {}

    function setSaleStartTime(uint32 newSaleStartTime) public onlyOwner {
        saleStartTime = newSaleStartTime;
    }
    
    function unlockAll() external onlyOwner {
        unlockFlag = true;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }    

    function setMaxAmountPerMint(uint256 newMaxAmountPerMint) external onlyOwner {
        maxAmountPerMint = newMaxAmountPerMint;
    }

    /**
     * metadata URI
     */
    string private _baseURIExtended = "";

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * withdraw
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(wallet1), balance * 57 / 100);
        Address.sendValue(payable(wallet2), balance * 20 / 100);
        Address.sendValue(payable(wallet3), balance * 20 / 100);
        Address.sendValue(payable(wallet4), address(this).balance);
    }

    /**
     * reserve
     */
    function reserve(address account, uint256 amount) public onlyOwner {
        require(totalSupply() >= freeAmount, "Can't reserve until free mint finished.");
        require(reservedAmount < reserveAmount, "Exceeded reserve amount");
        require(amount <= maxAmountPerMint, "Exceeded max tx mint amount");
        
        uint256 mintableAmount = Math.min(amount, maxSupply - totalSupply());
        mintableAmount = Math.min(mintableAmount, reserveAmount - reservedAmount);
        
        require(mintableAmount > 0, "Nothing to mint");

        _safeMint(account, mintableAmount);
        reservedAmount = reservedAmount + mintableAmount;
    }

    /**
     * whitelist
     */
    function whitelist(address[] memory wallets) external onlyOwner {
        for(uint256 i =0; i < wallets.length; i++) {
            guaranteedWallets[wallets[i]] = true;
        }
        guaranteedMinAmount = guaranteedMinAmount + wallets.length;
    }

    /**
     * mint
     */
    function mint(uint amount) external payable {
        require(msg.sender == tx.origin, "User wallet required");
        require(saleStartTime != 0 && saleStartTime <= block.timestamp, "Sales is not started");        
        require(totalSupply() < maxSupply, "Exceeds max supply");

        uint256 mintableAmount;

        if(totalSupply() < freeAmount) {
            require(balanceOf(msg.sender) < maxFreeMintPerWallet, "Free mint limit per wallet reached");

            uint256 availableFreeSupply = freeAmount - totalSupply();
            uint256 availableFreeMintAmount = maxFreeMintPerWallet - balanceOf(msg.sender);
            mintableAmount = Math.min(amount, availableFreeMintAmount);
            mintableAmount = Math.min(mintableAmount, availableFreeSupply);

            require(mintableAmount > 0, 'Nothing to free mint');

            _safeMint(msg.sender, mintableAmount);

            if (msg.value > 0) {
                Address.sendValue(payable(msg.sender), msg.value);
            }
        } else {
            require(amount <= maxAmountPerMint, "Exceeded max tx mint amount");

            uint256 availableSupply = maxSupply - totalSupply() - (reserveAmount - reservedAmount);
            if(!unlockFlag) {
                availableSupply = availableSupply - guaranteedMinAmount;
                if(guaranteedWallets[msg.sender] && !guaranteedWalletMint[msg.sender])
                    availableSupply = availableSupply + 1;
            }

            mintableAmount = Math.min(amount, availableSupply);
            require(mintableAmount > 0, 'Nothing to mint');

            uint256 totalMintCost = mintableAmount * mintPrice;
            require(msg.value >= totalMintCost, "Not enough ETH sent; check price!"); 

            _safeMint(msg.sender, mintableAmount);

            if(guaranteedWallets[msg.sender] && !guaranteedWalletMint[msg.sender]) {
                guaranteedWalletMint[msg.sender] = true;
                guaranteedMinAmount--;
            }

            // Refund unused fund
            uint256 changes = msg.value - totalMintCost;
            if (changes > 0) {
                Address.sendValue(payable(msg.sender), changes);
            }                
        }
    }
}