// SPDX-License-Identifier: MIT
// Created by https://twitter.com/BeforeMintNFT

//  ______          _        _______      ______               ______   
// |_   _ \        / \      |_   __ \   .' ___  |             / ____ `. 
//   | |_) |      / _ \       | |__) | / .'   \_|    _   __   `'  __) | 
//   |  __'.     / ___ \      |  ___/  | |          [ \ [  ]  _  |__ '. 
//  _| |__) |  _/ /   \ \_   _| |_     \ `.___.'\    \ \/ /  | \____) | 
// |_______/  |____| |____| |_____|     `.____ .'     \__/    \______.' 

pragma solidity ^0.8.4;

import "./erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BoredApePixelClubV3 is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;

	string public baseTokenURI;


    address public addressDeposit;

	uint256 public constant maxSupply = 2770;
	uint256 public mintPrice = 0.055 ether;
    uint256 public maxMintPerWallet;

    bool public mintPaused = false;

    event Minted(address indexed owner, uint quantity, uint totalMinted);
    event MintPriceChanged(uint value);
    event MintPaused(bool value);
    
    constructor(string memory _initBaseURI,
                uint256 _maxPerMintPerWallet,
                address _addressDeposit
        ) ERC721A("Bored Ape Pixel Club V3", "BAPC") {
        baseTokenURI = _initBaseURI;
        maxMintPerWallet = _maxPerMintPerWallet;
        addressDeposit = _addressDeposit;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Public mint 
    function mint(uint256 quantity) external payable nonReentrant callerIsUser {
        require(!mintPaused, "Mint is paused");

        uint256 totalCost = mintPrice * quantity;
        uint256 totalMinted = totalSupply() + quantity;
        require(msg.value >= totalCost, "Not enough balance for mint the quantity supplied");
        require(totalMinted  <= maxSupply, "Not enough supply left for this mint quantity");

        require( numberMinted(msg.sender) + quantity <= maxMintPerWallet, "Can not mint this many");
        
        _safeMint(msg.sender, quantity);

        refundIfOver(totalCost);

        emit Minted(msg.sender, quantity, totalMinted);
    }

    // Giveaway mint
    function giveaway(uint256 quantity) external payable onlyOwner nonReentrant  {
        uint256 totalMinted = totalSupply() + quantity;
        require(totalMinted <= maxSupply, "Not enough supply left for this mint quantity");
        
        _safeMint(msg.sender, quantity);

        emit Minted(msg.sender, quantity, totalMinted);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

	function _startTokenId() internal view virtual override returns (uint256) {
		return 2230;
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
        emit MintPriceChanged(_mintPrice);
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) external onlyOwner {
        maxMintPerWallet = _maxMintPerWallet;
    }

    function setAddressDeposit(address _addressDeposit) external onlyOwner {
        addressDeposit = _addressDeposit;
    }
    
    function setMintPaused(bool _mintPaused) external onlyOwner {
        mintPaused = _mintPaused;
        emit MintPaused(_mintPaused);
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

	function withdraw() external onlyOwner nonReentrant {
        (bool s, ) = payable(addressDeposit).call{value: address(this).balance}("");
        require(s, "Address: unable to withdraw");
	}

	receive() external payable {
	}

	fallback() external payable {
		(bool s, ) = payable(owner()).call{value: address(this).balance}("");
        require(s, "Address: unable to send value");
	}

}