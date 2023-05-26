// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//   ____    _    ____    _____  _  _____ _____ ___   ___  ____
//  | __ )  / \  |  _ \  |_   _|/ \|_   _|_   _/ _ \ / _ \/ ___|
//  |  _ \ / _ \ | | | |   | | / _ \ | |   | || | | | | | \___ \
//  | |_) / ___ \| |_| |   | |/ ___ \| |   | || |_| | |_| |___) |
//  |____/_/   \_\____/    |_/_/   \_\_|   |_| \___/ \___/|____/

contract BadTattoos is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public maxSupply = 6000;

    mapping(address => bool) presales;
    mapping(uint => bool) public tokensExist;

    uint public price = 0.06 ether;
    uint public presalePrice = 0.04 ether;

    uint public quantity = 10;

    string public baseTokenURI;

    bool private _paused = false;
    bool private _isPresale = true;
    bool private _hasTeamReserved = false;

    constructor(string memory baseURI) ERC721("Bad Tattoos", "BadTattoos") {
        setBaseURI(baseURI);
        _tokenIds.increment();
    }

    function mint(uint _quantity) public payable {
        uint totalMinted = _tokenIds.current();

        uint256 mintLimit = maxSupply + 1;

        require(!_paused, "Sale paused");
        require(totalMinted + _quantity <= mintLimit, "Not enough remaining!");
        require(_quantity <= quantity, "Invalid quantity");

        if (_isPresale) {
            require(verifyUser(msg.sender), "You are not on the presale");
            require(
                msg.value == presalePrice * _quantity,
                "Insufficient funds to redeem"
            );
        } else {
            require(
                msg.value == price * _quantity,
                "Insufficient funds to redeem"
            );
        }

        for (uint i = 0; i < _quantity; i++) {
            uint id = _mintNFT();
            tokensExist[id] = true;
        }
    }

    function _mintNFT() private returns (uint id) {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);

        id = newTokenID;
        _tokenIds.increment();

        return id;
    }

    function addUsers(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            presales[_addresses[i]] = true;
        }
    }

    function verifyUser(address _address) public view returns (bool) {
        bool userIsPresale = presales[_address];
        return userIsPresale;
    }

    function hasToken() private view returns (uint balance) {
        balance = balanceOf(msg.sender);
    }

    function getTokens() public view returns (uint[] memory) {
        uint balance = hasToken();
        uint[] memory tokens = new uint[](balance);

        for (uint i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(msg.sender, i);
        }

        return tokens;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawAmount(uint amount) public onlyOwner {
        require(amount < address(this).balance, "Balance too low for amount");
        payable(owner()).transfer(amount);
    }

    function reserveNFTs() public onlyOwner {
        require(!_hasTeamReserved, "Team already reserved");

        for (uint i = 0; i < 15; i++) {
            _mintNFT();
        }

        _hasTeamReserved = true;
    }

    function getPresaleState() public view returns (bool isPresale) {
        isPresale = _isPresale;
        return isPresale;
    }

    function getPausedState() public view returns (bool isPaused) {
        isPaused = _paused;
        return isPaused;
    }

    function pauseSale() public onlyOwner {
        _paused = true;
    }

    function unpauseSale() public onlyOwner {
        _paused = false;
    }

    function preSaleStart() public onlyOwner {
        _isPresale = true;
    }

    function preSaleStop() public onlyOwner {
        _isPresale = false;
    }

    function getPrice(uint _quantity)
        public
        view
        returns (uint totalPrice)
    {
        if (_isPresale) {
            totalPrice = presalePrice * _quantity;
        } else {
            totalPrice = price * _quantity;
        }

        return totalPrice;
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function getMaxSupply() public view returns (uint256 _maxSupply) {
        _maxSupply = maxSupply;
        return _maxSupply;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
}