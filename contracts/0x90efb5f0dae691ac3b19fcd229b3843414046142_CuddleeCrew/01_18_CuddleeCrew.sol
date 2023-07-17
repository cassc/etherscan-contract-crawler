// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './ERC721Tradable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";

contract CuddleeCrew is ERC721Tradable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;
    string public baseURI;
    string public contractURI;
    uint256 public maxSupply = 20000;
    uint256 public cost = 0.02 ether; // Price for whitelist and first week of main sale, then 0.04
    uint256 public maxMintAmount = 20;
    bool public paused = false;
    bool public mainSale = false; // Main Sale is disabled by default
    mapping(address => bool) public presaleAccessList; // Whitelist for pre-sale
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _contractURI,
        address _proxyRegistryAddress
    )
    ERC721Tradable( _name, _symbol, _proxyRegistryAddress)
    {
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        setBaseURI(_initBaseURI);
        setContractURI(_contractURI);
        mint(100); // Mint first 100 for team
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Need to Mint 1 or More");
        require(supply + _mintAmount <= maxSupply, "Max NFTs minted.");

        if (msg.sender != owner()) {
            if(!mainSale){
                require(hasPresaleAccess(msg.sender), "You are not whitelisted for the Cuddlee Crew pre-sale, wait opening main sale");
            }
            require(_mintAmount <= maxMintAmount, "You can only Mint 20");
            require(msg.value >= cost * _mintAmount, "Insufficient Funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(msg.sender, currentTokenId);
        }
    }
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function updateMainSaleStatus(bool _mainSale) public onlyOwner {
        mainSale = _mainSale;
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function withdraw(uint256 _amount) public payable onlyOwner {
        require(payable(msg.sender).send(_amount));
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    function setPresaleAccessList(address[] memory _addressList) public onlyOwner {
        for (uint256 i; i < _addressList.length; i++) {
            presaleAccessList[_addressList[i]] = true;
        }
    }
    function hasPresaleAccess(address wallet) public view returns (bool) {
        return presaleAccessList[wallet];
    }
}