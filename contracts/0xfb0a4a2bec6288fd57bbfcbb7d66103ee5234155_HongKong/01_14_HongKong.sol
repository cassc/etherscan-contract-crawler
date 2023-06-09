// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


contract HongKong is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    string public baseURI = "";
    uint256 public maxSupplyAmount = 2500;

    string public notRevealedURI= "https://gateway.moralisipfs.com/ipfs/QmPuuANToeVZt4uqpCs2CYXxZEVvinu7DRjhbrSuXwnUAa";
    bool public revealed = false;
    bool public started = false;
    uint256 public publicSalePrice = 0;

    constructor() ERC721A("The Forever Blooming Bauhinia", "TFBB") {
        setFeeNumerator(1000);
    }

    function mint(uint256 amount) external payable {
        require(started, "Sale is not started");
        require(amount + totalSupply() <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");

        uint256 requiredValue = publicSalePrice * amount;
        require(msg.value >= requiredValue, "Insufficient fund");
        _safeMint(msg.sender, amount);

        if (msg.value > requiredValue) {
            payable(msg.sender).sendValue(msg.value - requiredValue);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(revealed == false) {
            return notRevealedURI;
        }

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /********** onlyOwner ********/
    function multidevmint(address [] calldata tos, uint32 [] calldata amounts) external onlyOwner {
        require(tos.length == amounts.length, "tos length must eq amounts");
        for(uint l = 0; l < tos.length; l ++) {
            require(amounts[l] + totalSupply() <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");
            _safeMint(tos[l], amounts[l]);
        }
    }

    function setNotRevealedURI(string memory newBaseURI) external onlyOwner {
        notRevealedURI = newBaseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setStarted(bool _started) external onlyOwner {
        started = _started;
    }

    function setMaxSupply(uint32 _newValue) external onlyOwner {
        maxSupplyAmount = _newValue;
    }

    function setPrice(uint256 _newValue) external onlyOwner {
        publicSalePrice = _newValue;
    }

    function withdraw() external onlyOwner {
        payable(owner()).sendValue(address(this).balance);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}