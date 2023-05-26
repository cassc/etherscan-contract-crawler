/*******************************************************************************************************************
 .-.    .---..-.   .-..----.      .--.  .----. .----. .-..----..-----..----..----.     .----..-..---. .-.    .----. 
 } |   / {-. \\ \_/ / } |__}     / {} \ } {-. \} {-. \{ || }`-'`-' '-'} |__}} {-. \    | |--'{ |} }}_}} |   { {__-` 
 } '--.\ '-} / \   /  } '__}    /  /\  \} '-} /} '-} /| }| },-.  } {  } '__}} '-} /    | }-`}| }| } \ } '--..-._} } 
 `----' `---'   `-'   `----'    `-'  `-'`----' `----' `-'`----'  `-'  `----'`----'     `----'`-'`-'-' `----'`----'  
********************************************************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./common/StellarBase.sol";

// メインコントラクト
contract Love_Addicted_Girls is StellarBase {
    using Strings for uint256;

    mapping(address => uint256) private _whiteLists;
    uint256 private _whiteListCount;

    uint256 private _saleCount;

    bool private _isPublicSale;
    bool private _isPreSale;

    string private _BASE_URI;

    constructor()
    StellarBase("Love Addicted Girls", "LAG") {
        _isPublicSale = false;
        _isPreSale = false;
        _saleCount = 4000;
        _whiteListCount = 0;
        _BASE_URI = "https://ipfs.io/ipfs/QmTYNytZYkKjUaizJJbLx6GysWBDi3vk8hYWEAKdKi2MAV/";
    }

    function setBaseURI(string memory base_uri)
        public
        virtual
        onlyOwner
    {
        _BASE_URI = base_uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_BASE_URI, tokenId.toString(), '.json'));
    }

    function startPreSale()
        public
        virtual
        onlyOwner
    {
        _isPublicSale = false;
        _isPreSale = true;
    }

    function startPublicSale()
        public
        virtual
        onlyOwner
    {
        _isPublicSale = true;
        _isPreSale = false;
    }

    function pausePreSale()
        public
        virtual
        onlyOwner
    {
        _isPreSale = false;
    }

    function pausePublicSale()
        public
        virtual
        onlyOwner
    {
        _isPublicSale = false;
    }

    function updateSaleCount(uint256 count)
        internal
        virtual
        onlyOwner
    {
        _saleCount = count;
    }

    function deleteWL(address addr)
        public
        virtual
        onlyOwner
    {
        _whiteListCount = _whiteListCount - _whiteLists[addr];
        delete(_whiteLists[addr]);
    }

    function upsertWL(address addr, uint256 maxMint)
        public
        virtual
        onlyOwner
    {
        _whiteListCount = _whiteListCount - _whiteLists[addr];
        _whiteLists[addr] = maxMint;
        _whiteListCount = _whiteListCount + maxMint;
    }

    function pushMultiWL(address[] memory list)
        public
        virtual
        onlyOwner
    {
        for (uint i = 0; i < list.length; i++) {
            _whiteLists[list[i]]++;
            _whiteListCount++;
        }
    }

    function _ownerMint(uint256 count)
        public
        virtual
        onlyOwner
    {
        uint256 currentNumber = totalSupply() + 1;

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), currentNumber + i);
        }
    }

    function _preSaleMint(uint256 count)
        public
        virtual
        payable
    {
        require(msg.value >= (0.05 ether * count), "Need to send ETH");
        require(_isPreSale, "Can not presale");
        require(_whiteLists[_msgSender()] - count >= 0, "Can not whitelist");
        require(totalSupply() < _saleCount, "Can not mint");

        uint256 currentNumber = totalSupply() + 1;

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), currentNumber + i);
            _whiteLists[_msgSender()]--;
        }
    }

    function _publicSaleMint(uint256 count)
        public
        virtual
        payable
    {
        require(msg.value >= (0.05 ether * count), "Need to send ETH");
        require(_isPublicSale, "Can not sale");
        require(totalSupply() < _saleCount, "Can not mint");
        require(count < 3, "mint limit over");

        uint256 currentNumber = totalSupply() + 1;

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), currentNumber + i);
        }
    }

    function isPreSale()
        public
        view
        returns(bool)
    {
        return _isPreSale;
    }

    function isPublicSale()
        public
        view
        returns(bool)
    {
        return _isPublicSale;
    }

    function saleLimit()
        public
        view
        returns(uint256)
    {
        return _saleCount;
    }

    function whiteListCountOfOwner(address owner)
        public
        view
        returns(uint256)
    {
        return _whiteLists[owner];
    }

    function whiteListCount()
        public
        view
        returns(uint256)
    {
        return _whiteListCount;
    }
    
}