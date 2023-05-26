// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TheIndifferentDuck is ERC721Enumerable, Ownable {
    string _baseTokenURI = 'https://theindifferentduck.com/api/ducks/';

    uint256 private _maxPurchase = 10;
    uint256 private _reserved = 17;
    uint256 private _price = 0.04 ether;
    uint256 public constant MAX_DUCKS = 10000;

    uint256 public saleState = 0; // 0 = paused, 1 = presale, 2 = live

    // list of addresses that have a number of reserved tokens for presale
    mapping(address => uint256) private _preSaleWhitelist;

    address t1 = 0xC6519c6e6d8CF28d39cb07E7589B2F55235C6DAa;
    address t2 = 0xa3E21d485632D0968E61f6466296393Cef81D7d1;
    address t3 = 0x1FA44712Ac662f5A3155A144A1758Bd4a9660b0E;
    address t4 = 0xF7fB9D8ce745310296b97bAFe63E6cbAD45bFe15;
    address t5 = 0x57b090BA902578996Db810e9f3140bd73EA8495e;

    constructor() ERC721('The Indifferent Duck', 'IndifferentDuck') {
        // team gets the first 5
        _safeMint(t1, 1);
        _safeMint(t2, 2);
        _safeMint(t3, 3);
        _safeMint(t4, 4);
        _safeMint(t5, 5);
    }

    function giveAway(address _toAddress, uint256 numberOfTokens)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();

        require(numberOfTokens <= _reserved, 'Exceeds reserved supply');

        _reserved -= numberOfTokens;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(_toAddress, supply + i);
        }
    }

    function preSaleMintDuck(uint256 numberOfTokens) public payable {
        uint256 supply = totalSupply();
        uint256 reservedAmount = _preSaleWhitelist[msg.sender];

        require(saleState > 0, 'Presale must be active to mint');
        require(reservedAmount > 0, 'No tokens reserved for address');
        require(
            numberOfTokens <= reservedAmount,
            "Can't mint more than reserved"
        );
        require(
            supply + numberOfTokens <= MAX_DUCKS - _reserved,
            'Purchase would exceed max supply of Ducks'
        );
        require(
            msg.value >= _price * numberOfTokens,
            'Ether sent is not correct'
        );

        _preSaleWhitelist[msg.sender] -= numberOfTokens;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintDuck(uint256 numberOfTokens) public payable {
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {
            require(saleState > 1, 'Sale must be active to mint');
        }
        require(
            numberOfTokens <= _maxPurchase,
            'You can only mint 10 tokens at a time'
        );
        require(
            supply + numberOfTokens <= MAX_DUCKS - _reserved,
            'Purchase would exceed max supply of Ducks'
        );
        if (msg.sender != owner()) {
            require(
                msg.value >= _price * numberOfTokens,
                'Ether sent is not correct'
            );
        }

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function setSaleState(uint256 _saleState) public onlyOwner {
        saleState = _saleState;
    }

    function getPreSaleReservedAmount(address _address)
        public
        view
        returns (uint256)
    {
        return _preSaleWhitelist[_address];
    }

    function setPreSaleWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            _preSaleWhitelist[_addresses[i]] = 10;
        }
    }

    // withdraw

    function withdrawPartial() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 5;
        require(payable(t1).send(_each));
        require(payable(t2).send(_each));
        require(payable(t3).send(_each));
        require(payable(t4).send(_each));
        require(payable(t5).send(_each));
    }
}