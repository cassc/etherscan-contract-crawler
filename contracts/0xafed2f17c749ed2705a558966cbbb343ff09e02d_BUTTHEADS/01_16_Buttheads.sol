pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&%,,,,,.,,,,,,#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@&&&%,,,,,,,,,,,,,,,,,,,,,%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@&&(,,,,,,.,,,,,,,,,,,,,,,,,,,&&@@@@@@@@@@&&&@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@&#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&@@@@@@@&&#  &&@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&/,,,,,,,,,.,,,,,,,,,,,,,,,.,,,,,,&&&@@&&&   #&@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@&&,,,,,,,,,,,,,,,,,,,,,,,,,,,#,,,,,,,*&&&  .#(/&&@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@&#,,,,,,,,,,.,,,,,,,,,,,,,&(%(,,,,,,,,,,%&*    (&@@@@@@@@@@@
// @@@@@@@@@&&@@@@@@@@@&#,,,,,,,,,,,,,,,,,,,,,,,,,,%&(,,,,,,,,,,,&&&&&&@@@@@@@@@@@@
// @@@@@@@@@&&(&&&&@@@@&&,,.,,,.,,,.,,,.,,,.,,,.,,,.,%&/,,,..   ,,&& .&&@@@@@@@@@@@
// @@@@@@@@@@&%    #&&&&&*,,,,,,,,,,,,,,,,,,,,,,,. .,,*&%,,,.    ,*&&&@@@@@@@@@@@@@
// @@@@@@@@@@@&&&&(.    *&&%,,,,,,,.,,,,,,,,,,,,     ,,*&*,,.    ,*&@@@@@@@@@@@@@@@
// @@@@@@@@@@@@&&*             .,,,,,,,,,,,,,,,,     ,,,&%,,    .,&&@@@@@@@@@@@@@@@
// @@@@@@@@@@@@&&&&&&&%          ,,.,,,,,,,,,,,.    .,,*&/,.  .,*&&@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&&   ,%&     /&,,,,,,,,,,,       ,,*&&,,,,,#&&@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@&&&&@&&,   &&#,.,,,,,,,,,.   .,,,&&*,/%&&&@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@&&#,,,,,,,,,,,,,&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./RandomlyAssigned.sol";

contract BUTTHEADS is ERC721Enumerable, RandomlyAssigned, Ownable {
    using Strings for uint256;

    uint256 public _mintPrice = 0.06 ether;
    uint256 public _maxToMint = 18;
    uint256 public constant MAX_BUTTS = 8888;
    uint256 public _maxToMintPreSale = 8;

    string public proof = "";
    bool public _saleIsActive = false;
    bool public _preSaleIsActive = false;

    mapping(address => bool) private _preSaleList;
    mapping(address => uint256) private _preSaleListClaimed;

    address wallet1 = 0x8a8320ceb5D99b6BB5B3967f40f422E471BeD72B;
    address wallet2 = 0xeee23b04aE90243f7abCB15bCB914387D73895b9;

    bool public _blockSettingOfBaseUri = false;
    bool public _blockSettingProof = false;

    string private _contractURI = "";
    string private _tokenBaseURI = "";
    string private _tokenRevealedBaseURI = "";

    uint256 public startTimePreSale;
    uint256 public endTimePreSale;

    uint256 public startTimeSale;

    constructor() ERC721("BUTTHEADS", "BH") RandomlyAssigned(8888, 0) {}

    //modifiers
    modifier onlyPreSaleBuyers() {
        require(_preSaleList[_msgSender()], "You are not on the pre sale list");
        _;
    }

    // setters
    function setStartAndEndTimePreSale(uint256 _start, uint256 _end)
        external
        onlyOwner
    {
        startTimePreSale = _start;
        endTimePreSale = _end;
    }

    function setStartTimeSale(uint256 _startSale) external onlyOwner {
        startTimeSale = _startSale;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        _mintPrice = _price;
    }

    function setMaxButtsPerTX(uint256 _maxValue) external onlyOwner {
        _maxToMint = _maxValue;
    }

    function setPreSaleMaxMint(uint256 maxMint) external onlyOwner {
        _maxToMintPreSale = maxMint;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI)
        external
        onlyOwner
    {
        require(!_blockSettingOfBaseUri, "BaseURI can not be changed");
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!_blockSettingOfBaseUri, "BaseURI can not be changed");
        _tokenBaseURI = baseURI;
    }

    function blockSetBaseURIForever() external onlyOwner {
        _blockSettingOfBaseUri = true;
    }

    function blockSetProofForever() external onlyOwner {
        _blockSettingProof = true;
    }

    function setSaleState(bool val) external onlyOwner {
        _saleIsActive = val;
    }

    function setPreSaleState(bool val) external onlyOwner {
        _preSaleIsActive = val;
    }

    function setProof(string calldata proofString) external onlyOwner {
        require(!_blockSettingProof, "Proof can not be changed");
        proof = proofString;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return
            bytes(revealedBaseURI).length > 0
                ? string(abi.encodePacked(revealedBaseURI, tokenId.toString()))
                : _tokenBaseURI;
    }

    // presale
    function addToPreSaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Address can not be null");

            _preSaleList[addresses[i]] = true;

            _preSaleListClaimed[addresses[i]] > 0
                ? _preSaleListClaimed[addresses[i]]
                : 0;
        }
    }

    function onPreSaleList(address addr) external view returns (bool) {
        return _preSaleList[addr];
    }

    function removeFromPreSaleList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Address can not be null");
            _preSaleList[addresses[i]] = false;
        }
    }

    function buttsOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    //buying booties
    function reserveButts(address _to, uint256 _numberOfButts)
        external
        onlyOwner
    {
        require(_to != address(0), "invalid_address");
        require(
            totalSupply() + _numberOfButts <= MAX_BUTTS,
            "Purchase exceeds max supply"
        );

        for (uint256 i = 0; i < _numberOfButts; i++) {
            uint256 mintIndex = nextToken();
            if (totalSupply() < MAX_BUTTS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mintButt(uint256 _numberOfButts) external payable {
        require(_saleIsActive, "Sale is not active");
        require(!_preSaleIsActive, "Pre Sale is still active");
        require(_numberOfButts <= _maxToMint, "You requested too many Butts");
        require(block.timestamp >= startTimeSale, "Sale did not start yet");
        require(
            totalSupply() + _numberOfButts <= MAX_BUTTS,
            "Purchase exceeds max supply"
        );
        require(
            _mintPrice * _numberOfButts <= msg.value,
            "ETH value not correct"
        );

        for (uint256 i = 0; i < _numberOfButts; i++) {
            uint256 mintIndex = nextToken();
            if (totalSupply() < MAX_BUTTS) {
                _safeMint(_msgSender(), mintIndex);
            }
        }
    }

    function mintPreSaleButt(uint256 _numberOfPreSaleButts)
        external
        payable
        onlyPreSaleBuyers
    {
        require(_preSaleIsActive, "Pre Sale is not active");
        require(
            block.timestamp >= startTimePreSale,
            "Pre-Sale did not start yet"
        );
        require(block.timestamp <= endTimePreSale, "Pre-Sale is finished");

        require(
            _numberOfPreSaleButts <= _maxToMintPreSale,
            "You requested too many Butts"
        );
        require(
            totalSupply() + _numberOfPreSaleButts <= MAX_BUTTS,
            "Purchase exceeds max supply of pre sale Butts"
        );
        require(
            _preSaleListClaimed[_msgSender()] + _numberOfPreSaleButts <=
                _maxToMintPreSale,
            "Purchase exceeds max allowed"
        );
        require(
            _mintPrice * _numberOfPreSaleButts <= msg.value,
            "ETH value not correct"
        );

        for (uint256 i = 0; i < _numberOfPreSaleButts; i++) {
            uint256 mintIndex = nextToken();
            if (totalSupply() < MAX_BUTTS) {
                _preSaleListClaimed[msg.sender] += 1;
                _safeMint(_msgSender(), mintIndex);
            }
        }
    }

    // withdraw
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 wallet2Payment = (balance * 5) / 100;
        payable(wallet1).transfer(balance - wallet2Payment);
        payable(wallet2).transfer(wallet2Payment);
    }

    function changeWallet(address _newWallet1) external onlyOwner {
        wallet1 = _newWallet1;
    }

    function getWalletOne() public view returns (address) {
        return wallet1;
    }

    function withdrawToWalletOne() public onlyOwner {
        require(address(wallet1) != address(0), "No Wallet 1");
        uint256 _amount = address(this).balance;
        require(payable(wallet1).send(_amount));
    }
}