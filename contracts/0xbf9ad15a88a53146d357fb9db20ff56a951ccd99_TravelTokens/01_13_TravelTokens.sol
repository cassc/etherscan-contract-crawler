// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TravelTokens is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    address public constant DEV_ADDRESS =
        0x93AcBb034cb43Fe87F02De5a5e2bec2f9c9e409a;

    uint256 public tokenPrice = 0.07 ether;

    uint256 public constant MAX_SUPPLY = 420;

    bool public saleIsActive = false;
    bool public isPresale = true;

    uint256 public tokenReserve = 10;

    string private newBaseURI;

    mapping(address => bool) private whiteList;

    constructor() ERC721("Travel Tokens", "TTNFT") {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(DEV_ADDRESS).transfer(balance.mul(7).div(100));
        payable(msg.sender).transfer(address(this).balance);
    }

    function _totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function reserveTokens(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        uint256 supply = _totalSupply();
        require(
            _reserveAmount > 0 && _reserveAmount <= tokenReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            _tokenIdTracker.increment();
            _safeMint(_to, supply + i);
        }
        tokenReserve = tokenReserve.sub(_reserveAmount);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        newBaseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return newBaseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() public onlyOwner {
        isPresale = !isPresale;
    }

    function mintToken(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale not active");
        if (isPresale) {
            require(isWhiteListed(msg.sender), "Not whitelisted");
        }
        require(numberOfTokens == 1, "One NFT per mint");
        require(
            _totalSupply().add(numberOfTokens) <= MAX_SUPPLY,
            "Exceed max supply of Tokens"
        );
        require(
            msg.value >= tokenPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _totalSupply();
            if (_totalSupply() < MAX_SUPPLY) {
                _tokenIdTracker.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function setTokenPrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    function setWhiteList(address _address) public onlyOwner {
        whiteList[_address] = true;
    }

    function setWhiteListMultiple(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            setWhiteList(_addresses[i]);
        }
    }

    function removeWhiteList(address _address) public onlyOwner {
        whiteList[_address] = false;
    }

    function isWhiteListed(address _address) public view returns (bool) {
        return whiteList[_address];
    }
}