// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SuperDoodz is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    bool private _promoActive = false;
    bool private _saleActive = false;
    uint256 private immutable _cap;
    uint256 private _maxMintAtOnce = 20;
    uint256 private immutable _mintPrice = 0.07 ether;
    uint256 private immutable _promoMintPrice = 0.05 ether;
    uint256 private _currentDropped;
    string private _baseUri;

    constructor(
        uint256 cap_,
        string memory baseUri
    ) ERC721("Super Doodz", "SPDZ") {
        _cap = cap_;
        _baseUri = baseUri;
    }

    function mintSuperDoodz(
        uint256 amount
    ) external payable {
        uint minted = _tokenIds.current();
        require(amount > 0, "At least 1 doodz requiered");
        require(_saleActive, "Sale is innactive");
        require(minted < _currentDropped, "Wait for more Doodz drop");
        require(minted <= _cap, "Only 13000 Doodz available");
        require(amount <= _maxMintAtOnce, "You can't mint that many at once");
        require(msg.value == _mintPrice * amount, "Send the correct amount of eth");

        for (uint256 i = 0; i < amount; i++) {
            if (minted < _cap) {
                _mintSuperDoodz(msg.sender);
            }
        }
    }

    function mintPromoSuperDoodz(uint256 amount) external payable {
        uint minted = _tokenIds.current();
        require(_promoActive, "promo disabled");
        require(amount > 0, "At least 1 doodz requiered");
        require(minted < _currentDropped, "Wait for more Doodz drop");
        require(minted <= _cap, "Only 13000 Doodz available");
        require(amount <= _maxMintAtOnce, "You can't mint that many at once");
        require(msg.value == _promoMintPrice * amount, "Send the correct amount of eth");

        for (uint256 i = 0; i < amount; i++) {
            if (minted < _cap) {
                _mintSuperDoodz(msg.sender);
            }
        }
    }

    function giveAway(address[] memory to) external onlyOwner {
        uint minted = _tokenIds.current();
        require(minted < _currentDropped, "Wait for more Doodz drop");
        require(minted <= _cap, "Only 13000 Doodz available");
        
        for (uint256 i = 0; i < to.length; i++) {
            if (minted < _cap) {
                 _mintSuperDoodz(to[i]);
            }
        }
    }

    function _mintSuperDoodz(address to) internal  {
        _tokenIds.increment();
        uint itemId = _tokenIds.current();
        _safeMint(to, itemId);
    }

    function dropNext(uint amount) external onlyOwner{
        _currentDropped += amount;
    }

    function setBaseURI(string memory baseURI) external onlyOwner() {
        _baseUri = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    // let the admin set the maximum of possible mint at once
    function setMaxMintAtOnce(uint256 maxMintAtOnce) external onlyOwner {
        _maxMintAtOnce = maxMintAtOnce;
    }

    // activate deactivate the sale
    function toggleSale() external onlyOwner {
        _saleActive = !_saleActive;
    }

    // promo is kindof use for a pre-sale, will not be triggered during main phase sale
    function togglePromo() external onlyOwner {
        _promoActive = !_promoActive;
    }

    function saleActive() external view returns (bool){
        return _saleActive;
    }

    function promoActive() external view returns (bool) {
        return _promoActive;
    }

   function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintPrice() external view virtual returns (uint256) {
        return _mintPrice;
    }

    function currentMinted() external view virtual returns (uint256) {
        return _tokenIds.current();
    }
}