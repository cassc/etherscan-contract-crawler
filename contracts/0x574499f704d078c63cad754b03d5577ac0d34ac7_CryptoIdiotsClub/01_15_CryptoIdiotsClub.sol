// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/IERC721A.sol";
import "hardhat/console.sol";

contract CryptoIdiotsClub is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 private immutable maxSupply;
    uint256 private immutable freeSupply;
    uint256 private immutable teamSupply;
    uint256 private immutable walletLimit;
    uint256 private immutable price;

    uint256 private teamMinted;
    bool private mintStarted;

    string private baseURI;

    constructor(
        uint256 _maxSupply,
        uint256 _freeSupply,
        uint256 _teamSupply,
        uint256 _walletLimit,
        uint256 _price,
        string memory _baseURI
    ) ERC721A("CryptoIdiotsClub", "CIC") {
        maxSupply = _maxSupply;
        freeSupply = _freeSupply;
        teamSupply = _teamSupply;
        walletLimit = _walletLimit;
        price = _price;
        baseURI = _baseURI;
        setFeeNumerator(800);
    }

    function mint(uint256 amount) external payable {
        require(mintStarted, "Mint not started");
        require(amount > 0, "Request amount can not be zero");
        uint256 publicMinted = _publicMinted();
        uint256 publicSupply = _publicSupply();
        require(amount + publicMinted <= publicSupply, "Exceed max supply");

        uint256 minterMinted = _numberMinted(msg.sender);
        require(amount + minterMinted <= walletLimit, "Exceed wallet limit");
        uint256 freeAmount = amount;
        if (publicMinted <= freeSupply && amount + publicMinted > freeSupply) {
            freeAmount = freeSupply - publicMinted;
        }

        uint256 requiredValue = (amount - freeAmount) * price;
        require(msg.value >= requiredValue, "Insufficient fund");
        _safeMint(msg.sender, amount);
        if (msg.value > requiredValue) {
            payable(msg.sender).sendValue(msg.value - requiredValue);
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _publicMinted() public view returns (uint256) {
        return _totalMinted() - teamMinted;
    }

    function getWalletLimit() public view returns (uint256) {
        return walletLimit;
    }

    function getFreeSupply() public view returns (uint256) {
        return freeSupply;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function _publicSupply() public view returns (uint256) {
        return maxSupply - teamSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function teamMint(address to, uint32 amount) external onlyOwner {
        teamMinted += amount;
        require(teamMinted <= teamSupply, "Exceed max supply");
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool started) external onlyOwner {
        mintStarted = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}