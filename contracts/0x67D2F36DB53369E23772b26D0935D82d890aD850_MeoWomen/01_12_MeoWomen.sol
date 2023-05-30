// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MeoWomen is ERC721A, Ownable {
    // Pre Sale Price
    uint256 public preSalePrice = 0.08 ether;

    // Public Sale Price
    uint256 public publicSalePrice = 0.1 ether;

    // Supply 
    uint256 public immutable maxSupply = 4096;

    // Reserved
    uint256 public immutable reserved = 96;

    // Reserved Minted
    uint256 public reservedMinted = 0;

    // Base URI
    string private baseURI;

    // Is Presale Active
    bool public isPreSaleActive = true;

    // Presales Start TimeStamp
    uint256 public preSaleStartTimeStamp = 1652365440;

    // Presales End TimeStamp
    uint256 public preSaleEndTimeStamp = 1652451840;

    // Max Mint Per Wallet at Presales Period
    uint256 private maxPreSaleMintPerWallet = 3;
    
    // Address Redeemed Count at Presales Period
    mapping(address => uint256) private preSaleRedeemed;

    // Is Public Sale Active
    bool public isPublicSaleActive = true;

    // Normal Sales Start TimeStamp
    uint256 public publicSaleStartTimeStamp = 1652451840;

    // Merkle Root for Presale
    bytes32 public preSaleRoot;

    constructor()ERC721A("MeoWomen", "MWM"){}

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) external payable {
        require((totalSupply() + quantity) <= (maxSupply - reserved + reservedMinted), "All NFTs are minted");
        require(isPreSaleActive, "PreSale Is Inactive");
        require(isPreSalePeriod(), "Not In PreSale Period");
        require(msg.value >= preSalePrice * quantity, "Payment is not correct");
        require(
            MerkleProof.verify(
                proof,
                preSaleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Signature incorrect"
        );
        require((preSaleRedeemed[_msgSender()] + quantity) <= maxPreSaleMintPerWallet, "Exceed Pre Sale Mint Limit");

        preSaleRedeemed[_msgSender()] = preSaleRedeemed[_msgSender()] + quantity;

        _safeMint(_msgSender(), quantity);
    }

    function mint(uint256 quantity) external payable {
        require(_msgSender() == tx.origin, "Anti bot");
        require((totalSupply() + quantity) <= (maxSupply - reserved + reservedMinted), "All NFTs are minted");
        require(isPublicSaleActive, "Public Sale Is Inactive");
        require(isPublicSalePeriod(), "Not In Public Sale Period");
        require(msg.value >= publicSalePrice * quantity, "Incorrect Value");
        require(quantity <= 10, "Only 10 can be minted in a transaction.");

        _safeMint(_msgSender(), quantity);
    }

    function isPreSalePeriod() public view returns (bool) {
        return ((preSaleStartTimeStamp == 0) || (block.timestamp >= preSaleStartTimeStamp && block.timestamp < preSaleEndTimeStamp));
    }

    function isPublicSalePeriod() public view returns (bool) {
        return ((publicSaleStartTimeStamp == 0) || (block.timestamp >= publicSaleStartTimeStamp));
    }

    function getPreSaleRedeemed(address addr) public view returns (uint256) {
        return preSaleRedeemed[addr];
    }

    function setPreSaleStartTimeStamp(uint256 timestamp) external onlyOwner {
        preSaleStartTimeStamp = timestamp;
    }

    function setPreSaleEndTimeStamp(uint256 timestamp) external onlyOwner {
        preSaleEndTimeStamp = timestamp;
    }

    function setPublicSaleStartTimeStamp(uint256 timestamp) external onlyOwner {
        publicSaleStartTimeStamp = timestamp;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPresaleRoot(bytes32 root) external onlyOwner {
        preSaleRoot = root;
    }

    function setPresaleMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
        maxPreSaleMintPerWallet = maxPerWallet;
    }

    function togglePresaleActive() external onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }

    function toggleSaleActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function setPreSalePrice(uint256 newPrice) external onlyOwner {
        preSalePrice = newPrice;
    }

    function setPublicSalePrice(uint256 newPrice) external onlyOwner {
        publicSalePrice = newPrice;
    }

    function grantTokens(address[] calldata to, uint[] calldata quantity) external onlyOwner{
        require(to.length == quantity.length);
        for (uint256 i = 0; i < to.length; i++) {
            reservedMinted = reservedMinted + quantity[i];
            require(reservedMinted <= reserved, "All Reserved NFTs are minted");
            _safeMint(to[i], quantity[i]);
        } 
    }

    function burnTokens() external onlyOwner {
        uint256 remainCount = maxSupply - totalSupply();
        _safeMint(0x000000000000000000000000000000000000dEaD, remainCount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}