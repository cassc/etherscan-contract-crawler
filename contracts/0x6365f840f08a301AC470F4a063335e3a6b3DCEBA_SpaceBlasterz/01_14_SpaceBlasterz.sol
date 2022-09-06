// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SpaceBlasterz is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    bool public publicSale = false;
    mapping(address => bool) whitelist;

    mapping (uint256 => string) private revealURI;
    string public unrevealURI = "https://gateway.pinata.cloud/ipfs/Qmehr8tBnfPuN2m13wZvgmW5cnKYW9rinNM4td5Ny7uQjP";
    bool public reveal = false;

    bool private endSale = false;

    string private _baseURIextended = "https://ipfs.io/ipfs/";
    uint256 private _priceextended = 60000000000000000;

    uint256 public tokenMinted = 0;
    bool public pauseMint = true;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdentifiers;

    uint256 public constant MAX_NFT_SUPPLY = 5555;
    uint256 public constant MaxBatchSize = 10;

  constructor() ERC721A("SpaceBlasterz", "SPB") {}

    function setEndSale(bool _endSale) public onlyOwner {
        endSale = _endSale;
    }

    function setWhitelist(address _add) public onlyOwner {
        require(_add != address(0), "Zero Address");
        whitelist[_add] = true;
    }

    function setWhitelistAll(address[] memory _adds) public onlyOwner {
        for(uint256 i = 0; i < _adds.length; i++) {
            address tmp = address(_adds[i]);
            whitelist[tmp] = true;
        }
    }

    function setPublicSale(bool _publicSale) public onlyOwner {
        _priceextended = 80000000000000000;
        publicSale = _publicSale;
    }

    function getNFTBalance(address _owner) public view returns (uint256) {
       return ERC721A.balanceOf(_owner);
    }

    function getNFTPrice() public view returns (uint256) {
        require(tokenMinted < MAX_NFT_SUPPLY, "Sale has already ended");
        return _priceextended;
    }

    function claimNFTForOwner(uint256 _cnt) public onlyOwner {
        require(!pauseMint, "Paused!");
        require(tokenMinted < MAX_NFT_SUPPLY, "Sale has already ended");

        _tokenIdentifiers.increment();
        
        _safeMint(msg.sender, _cnt);
        tokenMinted = tokenMinted + _cnt;
    }

    function mintNFT(uint256 _cnt) public payable {
        require(_cnt > 0);
        require(!pauseMint, "Paused!");
        require(tokenMinted < MAX_NFT_SUPPLY, "Sale has already ended");
        require(getNFTPrice().mul(_cnt) == msg.value, "ETH value sent is not correct");

        if(!publicSale) {
            require(whitelist[msg.sender], "Not ");
            require(_cnt <= 3, "Exceded the Minting Count");
        }

        if(publicSale) {
            require(_cnt <= 4, "Exceded the Minting Count");
        }

        _safeMint(msg.sender, _cnt);
        tokenMinted = tokenMinted + _cnt;

    }

    function withdraw() public onlyOwner() {
        require(endSale, "Ongoing Minting");
        require(reveal, "Ongoing Minting");
        uint balance = address(this).balance;
        address payable ownerAddress = payable(msg.sender);
        ownerAddress.transfer(balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(!reveal) return unrevealURI;
        return bytes(_baseURIextended).length > 0 ? string(abi.encodePacked(_baseURIextended, (tokenId+1).toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setUnrevealURI(string memory _uri) external onlyOwner() {
        unrevealURI = _uri;
    }

    function Reveal() public onlyOwner() {
        reveal = true;
    }

    function UnReveal() public onlyOwner() {
        reveal = false;
    }

    function _price() public view returns (uint256) {
        return _priceextended;
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               

    function getTokenMinted() public view returns (uint256) {
        return tokenMinted;
    }

    function setPrice(uint256 _priceextended_) external onlyOwner() {
        _priceextended = _priceextended_;
    }

    function pause() public onlyOwner {
        pauseMint = true;
    }

    function unPause() public onlyOwner {
        pauseMint = false;
    }
}