//
//   _____ _          _____ _ _ _       _
//  |_   _| |_ ___   |   __| |_| |_ ___| |_ ___ ___
//    | | |   | -_|  |  |  | | |  _|  _|   | -_|_ -|
//    |_| |_|_|___|  |_____|_|_|_| |___|_|_|___|___|
//
//
// The Glitches
// A free to mint 5k PFP project, focused on diversity and inclusion. We are community oriented.
//
// Twitter: https://twitter.com/theglitches_
//
// Project by:      @daniel100eth
// Art by:          @maxwell_step
// Code by:         @altcryp
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Glitches is ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Team
    address public constant sara        = 0x00796e910Bd0228ddF4cd79e3f353871a61C351C;
    address public constant daniel      = 0xF05155F792819710Da259C103D30e4B70178eA9f;
    address public constant maxwell     = 0x7745e475A272c825F191737f69793A05d28D6eb3;
    address public constant community   = 0xA2F58259ac7c83FB33B12827235A19a51c868ea2;

    // Glitches
    string public baseUri = 'https://api.theglitches.art/json/';

    // Sales
    bool public saleStart;
    bool public whitelistSale;
    bool public openForWhitelist;
    bool public preSale;
    bool public openForPresale;
    bool public sealContract;
    bool public enforceOnePerWallet = true;
    uint256 public constant presalePrice = .02 * 1e18;
    uint public constant maxSupply = 5000;
    uint public constant maxWhitelist = 1000;
    uint public constant maxPresale = 2000;

    uint256 public whitelisted;
    uint256 public presales;
    mapping (address => bool) public Minted;
    mapping (address => bool) public Whitelist;
    mapping (address => bool) public Presale;

    // Constructor
    constructor() ERC721("Glitches", "GLITCH") {
        for(uint256 i=0; i<10; i++) {
            _tokenIds.increment();
            _safeMint(sara, _tokenIds.current());
        }
        for(uint256 i=0; i<10; i++) {
            _tokenIds.increment();
            _safeMint(daniel, _tokenIds.current());
        }
        for(uint256 i=0; i<10; i++) {
            _tokenIds.increment();
            _safeMint(maxwell, _tokenIds.current());
        }
        for(uint256 i=0; i<30; i++) {
            _tokenIds.increment();
            _safeMint(community, _tokenIds.current());
        }
    }

    /*
    *   Getters.
    */
    function getCurrentId() public view returns(uint256) {
        return _tokenIds.current();
    }

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    /**
    *   Public function for minting.
    */
    function mintGlitch() public payable {
        uint256 totalIssued = _tokenIds.current();
        require(saleStart, "Wait for the sale to start!");
        require(totalIssued.add(1) <= maxSupply, "Exceeding max supply!");
        if(enforceOnePerWallet) {
            require(!Minted[msg.sender], "Only 1 per wallet.");
        }
        if(whitelistSale && preSale) {
            require(Whitelist[msg.sender] || Presale[msg.sender], "Only whitelist and presale minters.");
        } else if(whitelistSale) {
            require(Whitelist[msg.sender], "Only whitelist minters.");
        } else if(preSale) {
            require(Presale[msg.sender], "Only presale minters.");
        }

        _tokenIds.increment();
        _safeMint(msg.sender, _tokenIds.current());
        Minted[msg.sender] = true;
    }

    /**
    *   External function for getting all tokens by a specific owner.
    */
    function getByOwner(address _owner) view public returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = _tokenIds.current();
            uint256 resultIndex = 0;
            for (uint256 t = 1; t <= totalTokens; t++) {
                if (_exists(t) && ownerOf(t) == _owner) {
                    result[resultIndex] = t;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    /*
    *   Owner setters.
    */
    function setBaseUri(string memory _baseUri) public onlyOwner {
        require(!sealContract, "Contract must not be sealed.");
        baseUri = _baseUri;
    }

    function contractSettings(bool _saleStart, bool _whitelistSale, bool _openForWhitelist, bool _preSale, bool _openForPresale, bool _enforceOnePerWallet) public onlyOwner {
        saleStart = _saleStart;
        whitelistSale = _whitelistSale;
        openForWhitelist = _openForWhitelist;
        preSale = _preSale;
        openForPresale = _openForPresale;
        enforceOnePerWallet = _enforceOnePerWallet;
    }

    function setSealContract() public onlyOwner {
        sealContract = true;
    }

    function addSelfToPresale() public payable {
        require(openForPresale && presales.add(1) <= maxPresale, "Not eligible for presale.");
        require(msg.value >= presalePrice, "Presale price not met.");
        if(!Presale[msg.sender]) {
            Presale[msg.sender] = true;
            presales++;
        }
    }

    function addSelfToWhitelist() public {
        require(openForWhitelist && whitelisted.add(1) <= maxWhitelist, "Not eligible for whitelist.");
        if(!Whitelist[msg.sender]) {
            Whitelist[msg.sender] = true;
            whitelisted++;
        }
    }

    function addToWhitelist(address[] memory whitelist, uint256 total) public onlyOwner {
        require(whitelisted.add(total) <= maxWhitelist, "Would exceed total whitelist.");
        for(uint256 i=0; i<total; i++) {
            if(!Whitelist[whitelist[i]]) {
                Whitelist[whitelist[i]] = true;
                whitelisted++;
            }
        }
    }

    /*
    *   Money management.
    */
    function withdraw() public payable onlyOwner {
        uint256 _each = (address(this).balance / 2) / 3;
        require(payable(sara).send(_each));
        require(payable(daniel).send(_each));
        require(payable(maxwell).send(_each));
        require(payable(community).send(address(this).balance / 2));    // 50% for community
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    /*
    *   Overrides
    */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    receive () external payable virtual {}
}