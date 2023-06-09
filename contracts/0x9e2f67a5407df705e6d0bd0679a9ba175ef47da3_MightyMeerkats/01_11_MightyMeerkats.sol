//SPDX-License-Identifier: MIT
/*

___  ________ _____  _   _ _______   __ ___  ___ _____ ___________ _   __  ___ _____ _____
|  \/  |_   _|  __ \| | | |_   _\ \ / / |  \/  ||  ___|  ___| ___ \ | / / / _ \_   _/  ___|
| .  . | | | | |  \/| |_| | | |  \ V /  | .  . || |__ | |__ | |_/ / |/ / / /_\ \| | \ `--.
| |\/| | | | | | __ |  _  | | |   \ /   | |\/| ||  __||  __||    /|    \ |  _  || |  `--. \
| |  | |_| |_| |_\ \| | | | | |   | |   | |  | || |___| |___| |\ \| |\  \| | | || | /\__/ /
\_|  |_/\___/ \____/\_| |_/ \_/   \_/   \_|  |_/\____/\____/\_| \_\_| \_/\_| |_/\_/ \____/

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MightyMeerkats is ERC721, Ownable {
    uint256 public maxSupply = 10_000;
    uint256 public price = 0.10 ether;
    // Payment for Solidity contractor
    address public constant devAddress = 0x1C78a76c0B4a4C2f99ad8D0aBB7a1556Fa55Df59;
    uint256 public constant DEV_PAYMENT = 1.5 ether;

    // Flag to Toggle public and pre-sale
    bool public publicSaleOpen = false;

    // Admin config for max mint
    uint256 public maxMintPerTx = 10;
    uint256 public maxMintPerAddress = 10;
    mapping(address => uint256) public mintPerAddress;

    uint256 public currentSupply = 0;

    // Whitelist
    mapping(address => bool) public whitelistAddresses;
    bool public eligibleDevWithdrawal = true;

    string public publicURI;

    constructor() ERC721("MightyMeerkats", "MEERKATS") { }

    // Public Mint
    function mint(uint256 _count) public payable {
        require(publicSaleOpen, "public mint not open");
        require(_count <= maxMintPerTx, "max mint per tx");
        require(mintPerAddress[msg.sender] + _count <= maxMintPerAddress, "max mint per address");
        require(msg.value == _count * price, "invalid price");
        require(currentSupply + _count <= maxSupply, "max reached");

        mintPerAddress[msg.sender] += _count;
        for (uint256 i = 1; i <= _count; i++) {
            _safeMint(msg.sender, currentSupply + i);
        }
        currentSupply += _count;
    }


    // Will be set during reveal time
    function _baseURI() internal view override returns (string memory) {
        return publicURI;

    }

    // ************** Admin functions **************
    function togglePublicSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }


    function setMaxMintPerTx(uint256 _maxMint) external onlyOwner {
       maxMintPerTx = _maxMint;
    }

    function setMaxMintPerAddress(uint256 _maxMint) external onlyOwner {
        maxMintPerAddress = _maxMint;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(maxSupply > _maxSupply, "max supply cannot increase");
        require(currentSupply < _maxSupply, "max supply > current supply");
        maxSupply = _maxSupply;
    }

    function devWithdraw(address payable _to) external {
        require(_to == devAddress, "not dev wallet");
        require(eligibleDevWithdrawal, "already withdrew");
        require(address(this).balance >= DEV_PAYMENT, "not enough balance");

        eligibleDevWithdrawal = false;
        _to.transfer(DEV_PAYMENT);
    }


    function withdraw(address payable _to) external onlyOwner {
        require(_to != address(0), "cannot withdraw to address(0)");
        require(address(this).balance > 0, "empty balance");
        _to.transfer(address(this).balance);
    }


    // To set during reveal time
    function setPublicURI(string memory _uri) external onlyOwner {
        publicURI = _uri;
    }
}