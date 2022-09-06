// SPDX-License-Identifier: MIT

/**
 ______ _              ____               
/_  __/(_)___  __ __  / __ \ ____ ____ ___
 / /  / // _ \/ // / / /_/ // __// __/(_-<
/_/  /_//_//_/\_, /  \____//_/   \__//___/
             /___/                        

 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheTinyOrcs is Ownable, ERC721A, ReentrancyGuard {
    constructor() ERC721A("The Tiny Orcs", "ORCS") {}
    
    uint256 public collectionSize = 5555;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // For marketing etc.
    function reserveMintBatch(uint256[] calldata quantities, address[] calldata tos) external onlyOwner {
        for(uint256 i = 0; i < quantities.length; i++){
            require(
                totalSupply() + quantities[i] <= collectionSize,
                "Too many already minted before dev mint."
            );
            _safeMint(tos[i], quantities[i]);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        address amadeusAddress = address(0x718a7438297Ac14382F25802bb18422A4DadD31b);
        uint256 royaltyForAmadeus = address(this).balance / 100 * 10;
        uint256 remain = address(this).balance - royaltyForAmadeus;
        (bool success, ) = amadeusAddress.call{value: royaltyForAmadeus}("");
        require(success, "Transfer failed.");
        (success, ) = msg.sender.call{value: remain}("");
        require(success, "Transfer failed.");
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

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    //public sale
    function getPublicSalePrice(uint256 offset) public view returns(uint256){
        if (5255 < 500 + amountForPublicSale - offset){
            return 0.000000 ether;
        }
        return 0.003900 ether;
    }
    function getPublicSalePriceTotal(uint256 quantity) public view returns(uint256){
        uint256 totalPrice = 0;
        for(uint256 i = 0;i < quantity;i++){
            totalPrice += getPublicSalePrice(i);
        }
        return totalPrice;
    }
    bool public publicSaleStatus = false;
    uint256 public amountForPublicSale = 5255;
    // per mint public sale limitation
    uint256 public immutable publicSalePerMint = 5;

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        require(
        publicSaleStatus,
        "not begun"
        );
        require(
        totalSupply() + quantity <= collectionSize,
        "reached max supply"
        );
        require(
        amountForPublicSale >= quantity,
        "reached max amount"
        );

        require(
        quantity <= publicSalePerMint,
        "reached max amount per mint"
        );

        _safeMint(msg.sender, quantity);
        refundIfOver(getPublicSalePriceTotal(quantity));
        amountForPublicSale -= quantity;
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSaleStatus = status;
    }
}