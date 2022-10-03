// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YouAreNotAlone is ERC721A, Ownable {
    using Strings for uint256;

    uint16 public TOTAL_SUPPLY        = 333;
    uint8  public FREE_MINT           = 33;
    uint8  public MAX_PER_WALLET      = 2;
    uint8  public MAX_FREE_PER_WALLET = 1;
    uint8  public MAX_FOR_TEAM        = 12; // For promo, giveaways, etc.

    uint8  public freeMinted   = 0;
    uint8  public mintedByTeam = 0;
    bool   public isSaleActive = false;
    bool   private jsonFile    = false;
    uint64 public price        = 0.007 ether;

    mapping(address => bool) private freeMintByWallet;
    mapping(address => uint8) private nftByWallet;

    string private baseURI;

    constructor() ERC721A("You Are Not Alone", "YANA") {}

    function mint(uint8 _quantity) external payable {
        require(isSaleActive, "Sale is not active");
        require(msg.sender == tx.origin);
        require(totalMinted() + _quantity < TOTAL_SUPPLY + 1, "Max supply exceeded");

        if (nftByWallet[msg.sender] > 0) {
            nftByWallet[msg.sender] += _quantity;
        } else {
            nftByWallet[msg.sender] = _quantity;
        }
        require(nftByWallet[msg.sender] < MAX_PER_WALLET + 1, "2 NFTs max per wallet");

        // If free mint still active AND sender has not free minted
        if (freeMinted < FREE_MINT && !freeMintByWallet[msg.sender]) {
            require(msg.value >= price * (_quantity - 1), "Insufficient funds");

            if (msg.value <= price * _quantity) {
                freeMinted++;
                freeMintByWallet[msg.sender] = true;
            }
        } else {
            require(msg.value >= _quantity * price, "Insufficient funds");
        }

        _safeMint(msg.sender, _quantity);
    }

    function reserveNft(uint8 _quantity) public onlyOwner {
        require(totalMinted() + _quantity < TOTAL_SUPPLY + 1, "Max supply exceeded");
        require(mintedByTeam + _quantity < MAX_FOR_TEAM + 1, "Reached max for team");

        mintedByTeam = mintedByTeam + _quantity;

        _safeMint(msg.sender, _quantity);
    }

    function hasFreeMint(address _address) public view returns(bool) {
        return freeMintByWallet[_address] ? true : false;
    }

    function nftMintedByWallet(address _address) public view returns(uint) {
        return nftByWallet[_address] > 0 ? nftByWallet[_address] : 0;
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function flipJsonFileState() public onlyOwner {
        jsonFile = !jsonFile;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setJsonFileBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        jsonFile = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (jsonFile) {
            return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
        }

        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function setPrice(uint64 _price) external onlyOwner {
        price = _price;
    }

    function setSupply(uint16 _supply) external onlyOwner {
        require(totalMinted() < TOTAL_SUPPLY, "Sold out!");
        TOTAL_SUPPLY = _supply;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}