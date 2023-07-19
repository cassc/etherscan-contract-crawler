//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DamnPigz is ERC2981, ERC721AQueryable, Ownable{
    using Address for address payable;
    using Strings for uint256;

    uint256 public immutable price;
    uint32 public immutable MAX_TOKENS_PER_MINT;
    uint32 public immutable MAX_SUPPLY;
    uint32 public immutable _teamReserved;
    uint32 public immutable _walletLimit;

    bool public _started;
    uint32 public _teamMinted;
    string public _metadataURI = "ipfs://bafybeibwlffjisskohcc2ezafqa3mnn2v7ntl5xkk7uzf4tza2upb4gnpy/";

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

    constructor( uint256 _price, uint32 maxSupply, uint32 txLimit, uint32 walletLimit, uint32 teamReserved)
    ERC721A("Damn Pigiz", "DAMP") {
        price = _price;
        MAX_SUPPLY = maxSupply;
        MAX_TOKENS_PER_MINT = txLimit;
        _walletLimit = walletLimit;
        _teamReserved = teamReserved;

        _setDefaultRoyalty(owner(), 500);
    }

    function mint(uint32 amount) external payable {
        require(_started, "Sale is not started");
        require(amount + _totalMinted() <= MAX_SUPPLY +1 - _teamReserved, "Exceed max supply");
        require(amount < MAX_TOKENS_PER_MINT +1, "Exceed transaction limit");

        uint256 minted = _numberMinted(msg.sender);
        if (minted > 0) {
            require(msg.value >= amount * price, "Insufficient funds");
        } else {
            require(msg.value >= (amount - 1) * price, "Insufficient funds");
        }

        require(minted + amount < _walletLimit +1, "Exceed wallet limit");

        _safeMint(msg.sender, amount);
    }

    function _state(address minter) external view returns (HelperState memory) {
        return
            HelperState({
                price: price,
                txLimit: MAX_TOKENS_PER_MINT,
                walletLimit: _walletLimit,
                maxSupply: MAX_SUPPLY,
                teamReserved: _teamReserved,
                totalMinted: uint32(ERC721A._totalMinted()),
                userMinted: uint32(_numberMinted(minter)),
                started: _started
            });
    }

   function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721A).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function devMint(address to, uint32 amount) external onlyOwner {
        _teamMinted += amount;
        require (_teamMinted <= _teamReserved, "Exceed max supply");
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

//base https://etherscan.io/address/0xe3b271b7d0dbc883f1771c6243ad56f7fbdac2de#code