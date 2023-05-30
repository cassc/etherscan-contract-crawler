//"SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Whitelist.sol";

contract NFTContract is ERC721A, Ownable {
    using Strings for uint256;

    uint256 MAX_SALE_2_3 = 2;
    uint256 MAX_SALE_1 = 3;
    uint256 MAX_DAO_POOL = 100;
    uint256 MAX_SUPPLY = 7777;

    uint256 public mintRate = 0.2 ether;

    address MULTISIG1 = 0xdaBaCC1692A968d38010D6df14d8ae531bd4d9CB;
    address MULTISIG2 = 0x95aE15b6e37B7b095b8e191dA799a6411aa0A688;
    address MULTISIG3 = 0xC5B7f74be02c393856bB1FCdB56A4349dD5137a0;
    address DAO_POOL =  0xC41F90fcf3dCBC092Ca97813dC58BdA11FDb6513;

    uint256 BEGIN_SALE1 = 1646636400;
    uint256 BEGIN_SALE2 = 1646809200;
    uint256 BEGIN_SALE3 = 1646982000;

    struct BuyerData {
        uint64 numberMintedSale1;
        uint64 numberMintedSale2;
        uint64 numberMintedSale3;
    }

    string private contractUri = "";
    string public baseURI = "";
    mapping(address => BuyerData) public buyerData;

    constructor() ERC721A("Smol Boyz", "SMOLBOYZ") {}

    modifier onlyDAO(){
        require(msg.sender == DAO_POOL, "Only DAO Address is able to use this function!");
        _;
    }

    function mintSale1(uint256 quantity) external payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value == (mintRate * quantity), "Not enough ether sent");
        require(
            ((block.timestamp > BEGIN_SALE1) && (block.timestamp < (BEGIN_SALE1 + 86400))),
            "Sale is not currently ongoing"
        );
        require(quantity + _numberMintedSale1(msg.sender) <= MAX_SALE_1, "Exceeded the limit");
        _safeMint(msg.sender, quantity);
        buyerData[msg.sender].numberMintedSale1++;
    }

    function mintSale2(uint256 quantity) external payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value == (mintRate * quantity), "Not enough ether sent");
        require(
            ((block.timestamp > BEGIN_SALE2) && (block.timestamp < (BEGIN_SALE2 + 86400))),
            "Sale is not currently ongoing"
        );
        require(quantity + _numberMintedSale2(msg.sender) <= MAX_SALE_2_3, "Exceeded the limit");
        _safeMint(msg.sender, quantity);
        buyerData[msg.sender].numberMintedSale2++;
    }

    function mintSale3(uint256 quantity) external payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value == (mintRate * quantity), "Not enough ether sent");
        require(
            ((block.timestamp > BEGIN_SALE3) && (block.timestamp < (BEGIN_SALE3 + 86400))),
            "Sale is not currently ongoing"
        );
        require(quantity + _numberMintedSale3(msg.sender) <= MAX_SALE_2_3, "Exceeded the limit");
        _safeMint(msg.sender, quantity);
        buyerData[msg.sender].numberMintedSale3++;
    }

    function mintDAO(uint256 quantity) external payable onlyDAO {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value == (mintRate * quantity), "Not enough ether sent");
        require(quantity + _numberMinted(msg.sender) <= MAX_DAO_POOL, "Exceeded the limit");
        _safeMint(msg.sender, quantity);
    }

    function _numberMintedSale1(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(buyerData[owner].numberMintedSale1);
    }

    function _numberMintedSale2(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(buyerData[owner].numberMintedSale2);
    }

    function _numberMintedSale3(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(buyerData[owner].numberMintedSale3);
    }

    function withdraw(uint8 _safeIndex) external onlyOwner {
        require(address(this).balance > 0, "no balance");
        bool success = false;
        if(_safeIndex == 1) (success, ) = (payable(MULTISIG1)).call{value: address(this).balance}("");
        if(_safeIndex == 2) (success, ) = (payable(MULTISIG2)).call{value: address(this).balance}("");
        if(_safeIndex == 3) (success, ) = (payable(MULTISIG3)).call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function reveal(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory newContractUri) external onlyOwner {
        contractUri = newContractUri;
    }

    function contractURI() external view returns (string memory) {
        return contractUri;
    }

    function setSale3(uint256 _timestamp) external onlyOwner {
        BEGIN_SALE3 = _timestamp;
    }

    function setDaoPool(address _addr) external onlyOwner {
        DAO_POOL = _addr;
    }
}