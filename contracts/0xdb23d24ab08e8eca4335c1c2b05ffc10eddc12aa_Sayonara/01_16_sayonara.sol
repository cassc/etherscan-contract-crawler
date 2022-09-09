// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721AQueryable.sol";


contract Sayonara is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public _price;
    uint32 public immutable _maxSupply;
    uint32 public immutable _teamSupply;
    uint32 public immutable _walletLimit;

    uint32 public _teamMinted;
    bool public _started;
    string public _metadataURI = "https://meta.sayonara-nft.xyz/json/";

    struct Status {
        // config
        uint256 price;
        uint32 maxSupply;
        uint32 publicSupply;
        uint32 walletLimit;

        // state
        uint32 publicMinted;
        uint32 userMinted;
        bool soldout;
        bool started;
    }

    constructor(
        uint256 price,
        uint32 maxSupply,
        uint32 teamSupply,
        uint32 walletLimit
    ) ERC721A("Sayonara", "SAY") {
        require(maxSupply >= teamSupply);

        _price = price;
        _maxSupply = maxSupply;
        _teamSupply = teamSupply;
        _walletLimit = walletLimit;

        setFeeNumerator(750);
    }

    function mint(uint32 amount) external payable {
        require(_started, "Mint is not ready");

        uint32 publicMinted = _publicMinted();
        uint32 publicSupply = _publicSupply();
        require(amount + publicMinted <= _publicSupply(), "Sold Out");

        uint32 minted = uint32(_numberMinted(msg.sender));
        require(amount + minted <= _walletLimit, "max per wallet reached");

        uint32 freeAmount = 0;
        
        uint256 requiredValue = (amount - freeAmount) * _price;
        require(msg.value >= requiredValue, "Not enough ETH");

        _safeMint(msg.sender, amount);
        if (msg.value >= requiredValue) {
            payable(msg.sender).sendValue(msg.value - requiredValue);
        }
    }

    function _publicMinted() public view returns (uint32) {
        return uint32(_totalMinted()) - _teamMinted;
    }

    function _publicSupply() public view returns (uint32) {
        return _maxSupply - _teamSupply;
    }

    function _status(address minter) external view returns (Status memory) {
        uint32 publicSupply = _maxSupply - _teamSupply;
        uint32 publicMinted = uint32(ERC721A._totalMinted()) - _teamMinted;

        return Status({
            // config
            price: _price,
            maxSupply: _maxSupply,
            publicSupply:publicSupply,
            walletLimit: _walletLimit,

            // state
            publicMinted: publicMinted,
            soldout:  publicMinted >= publicSupply,
            userMinted: uint32(_numberMinted(minter)),
            started: _started
        });
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function devMint(address to, uint32 amount) external onlyOwner {
        _teamMinted += amount;
        require(_teamMinted <= _teamSupply, "Out of supply");
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}