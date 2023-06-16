// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract MinionSilhouete is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public immutable _price;
    uint32 public immutable _txLimit;
    uint32 public immutable _maxSupply;
    uint32 public immutable _teamReserved;
    uint32 public immutable _walletLimit;

    bool public _started;
    uint32 public _teamMinted;
    string public _metadataURI = "https://minion-silhouete.s3.us-east-1.amazonaws.com/json/";

    struct HelperState {
        uint256 price;
        uint32 txLimit;
        uint32 walletLimit;
        uint32 maxSupply;
        uint32 teamReserved;
        uint32 totalMinted;
        uint32 userMinted;
        bool started;
    }

    constructor( uint256 price, uint32 maxSupply, uint32 txLimit, uint32 walletLimit, uint32 teamReserved) ERC721A("MinionSilhouete", "MLT") {
        _price = price;
        _maxSupply = maxSupply;
        _txLimit = txLimit;
        _walletLimit = walletLimit;
        _teamReserved = teamReserved;

        _setDefaultRoyalty(owner(), 500);
    }

    function mint(uint32 amount) external payable {
        require(_started, "MinionSilhouete: Sale is not started");
        require(amount + _totalMinted() <= _maxSupply - _teamReserved, "MinionSilhouete: Exceed max supply");
        require(amount <= _txLimit, "MinionSilhouete: Exceed transaction limit");

        uint256 minted = _numberMinted(msg.sender);
        if (minted > 0) {
            require(msg.value >= amount * _price, "MinionSilhouete: insufficient funds");
        } else {
            require(msg.value >= (amount - 1) * _price, "MinionSilhouete: insufficient funds");
        }

        require(minted + amount <= _walletLimit, "MinionSilhouete: Exceed wallet limit");

        _safeMint(msg.sender, amount);
    }

    function _state(address minter) external view returns (HelperState memory) {
        return
            HelperState({
                price: _price,
                txLimit: _txLimit,
                walletLimit: _walletLimit,
                maxSupply: _maxSupply,
                teamReserved: _teamReserved,
                totalMinted: uint32(ERC721A._totalMinted()),
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
        require (_teamMinted <= _teamReserved, "MinionSilhouete: Exceed max supply");
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}