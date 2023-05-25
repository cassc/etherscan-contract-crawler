// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./WithdrawFairly.sol";

contract CosmicCowGirls is ERC721, Ownable, WithdrawFairly {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _burnedTracker;

    uint256 public constant MAX_ELEMENTS = 6969;
    uint256 public constant RESERVE_NFT = 120;
    uint256 public constant PRICE = 0.069 ether;
    uint256 public constant MAX_MINT_PRE_SALES = 2;
    uint256 public constant MAX_OWNED_PRE_SALES = 2;
    uint256 public constant MAX_MINT_SALES = 6;
    uint256 public constant START_AT = 1;

    uint256 public preSalesStart = 1634932800; // 2021-10-22 at 20:00:00 UTC
    uint256 public preSalesDuration = 1 days;
    uint256 public publicSalesStart = 1635019200; // 2021-10-23 at 20:00:00 UTC

    uint256 private constant HASH_SIGN = 8915721385;

    string public baseTokenURI;

    event EventPreSaleStartChange(uint256 _date);
    event EventPreSaleDurationChange(uint256 _duration);
    event EventPublicSaleStartChange(uint256 _date);
    event EventMint(uint256[] _tokens, uint256 _totalSupply);

    constructor(string memory baseURI) ERC721("CosmicCowGirls", "CCG") WithdrawFairly() {
        setBaseURI(baseURI);
    }

    //******************************************************//
    //                     Modifier                         //
    //******************************************************//
    modifier preSaleIsOpen {
        require(totalMinted() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(preSalesIsOpen(), "PreSales not open");
        }
        _;
    }
    modifier saleIsOpen {
        require(totalMinted() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(publicSalesIsOpen(), "PublicSales not open");
        }
        _;
    }

    //******************************************************//
    //                      Mint                            //
    //******************************************************//
    function preSalesMint(uint256 _count, bytes memory _signature) public payable preSaleIsOpen{

        address wallet = _msgSender();
        uint256 total = totalMinted();

        require(_count <= MAX_MINT_PRE_SALES, "Exceeds number");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(balanceOf(wallet) + _count <= MAX_OWNED_PRE_SALES, "Max minted");
        require(msg.value >= price(_count), "Value below price");
        require(preSalesSignature(wallet,_count,_signature) == owner(), "Not authorized to mint");

        uint256[] memory tokens = new uint256[](_count);

        for (uint256 i = 0; i < _count; i++) {
            tokens[i] = _mintAnElement(wallet);
        }

        emit EventMint(tokens, totalMinted());
    }
    function preSalesSignature(address _wallet, uint256 _count, bytes memory _signature) public pure returns(address){
        return ECDSA.recover(keccak256(abi.encode(_wallet, _count, HASH_SIGN)), _signature);
    }

    function publicSalesMint(uint256 _count) public payable saleIsOpen {

        address wallet = _msgSender();
        uint256 total = totalMinted();

        require(_count <= MAX_MINT_SALES, "Exceeds number");
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_count), "Value below price");

        uint256[] memory tokens = new uint256[](_count);

        for (uint256 i = 0; i < _count; i++) {
            tokens[i] = _mintAnElement(wallet);
        }

        emit EventMint(tokens, totalMinted());
    }

    function _mintAnElement(address _to) private returns(uint256){
        uint id = totalMinted() + START_AT;
        _tokenIdTracker.increment();
        _safeMint(_to, id);

        return id;
    }

    //******************************************************//
    //                      Base                            //
    //******************************************************//
    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current() - _burnedTracker.current();
    }
    function totalMinted() public view returns (uint256) {
        return _tokenIdTracker.current();
    }
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256 key = 0;
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = START_AT; i <= totalMinted(); i++) {
            if(rawOwnerOf(i) == _owner){
                tokensId[key] = i;
                key++;

                if(key == tokenCount){
                    break;
                }
            }
        }
        return tokensId;
    }
    function reserve(uint256 _count) public onlyOwner {
        uint256 total = totalMinted();
        require(total + _count <= RESERVE_NFT, "Exceeded");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
        }
    }

    //******************************************************//
    //                      States                          //
    //******************************************************//
    function preSalesIsOpen() public view returns (bool){
        return block.timestamp >= preSalesStart && block.timestamp <= preSalesStart + preSalesDuration;
    }
    function publicSalesIsOpen() public view returns (bool){
        return block.timestamp >= publicSalesStart;
    }

    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setPreSalesStart(uint256 _start) public onlyOwner {
        preSalesStart = _start;
        emit EventPreSaleStartChange(preSalesStart);
    }
    function setPreSalesDuration(uint256 _duration) public onlyOwner {
        preSalesDuration = _duration;
        emit EventPreSaleDurationChange(preSalesDuration);
    }
    function setPublicSalesStart(uint256 _start) public onlyOwner {
        publicSalesStart = _start;
        emit EventPublicSaleStartChange(publicSalesStart);
    }

    //******************************************************//
    //                      Brun                            //
    //******************************************************//
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner nor approved");
        _burnedTracker.increment();
        _burn(tokenId);
    }

}