// SPDX-License-Identifier: MIT
/**

|/    ,_     |)        ,_ _
|\(||`|||(|  |)|`(|(|()||_\
                   _|    

*/

/** 
    Project: Karma Bragons
    Website: karmabragons.com

    by RetroBoy (RetroBoy.dev)
*/

pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

contract KarmaBragons is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    mapping(address => uint256) public allowlistSpots;
    mapping(address => uint256) public freeClaims;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    uint256 public cost = 0.05 ether;
    uint256 public maxSupply = 4444;

    bool public allowlistSale = true;
    bool public paused = true;
    bool public revealed = true;

    address public dao; // 25%
    address public dev; // 10%
    address public artist; // 5%

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        address payable _dao,
        address payable _dev,
        address payable _artist
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        dao = _dao;
        dev = _dev;
        artist = _artist;
    }

    // internal

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public

    function mint(uint256 _amount) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "Sale is paused");
        require(_amount > 0, "Invalid mint amount");
        require(supply + _amount <= maxSupply, "Max supply exceeded");
        require(msg.value >= cost * _amount, "Not enough funds");

        if (allowlistSale == true) {
            isAllowlisted(msg.sender, _amount);
        }

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function freeClaim(uint256 _amount) public nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "Sale is paused");
        require(_amount > 0, "Invalid claim amount");
        require(supply + _amount <= maxSupply, "Max supply exceeded");

        isEligibleForClaim(msg.sender, _amount);

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintFor(address _to, uint256 _amount) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "Sale is paused");
        require(_amount > 0, "Invalid mint amount");
        require(supply + _amount <= maxSupply, "Max supply exceeded");
        require(msg.value >= cost * _amount, "Not enough funds");

        if (allowlistSale == true) {
            isAllowlisted(_to, _amount);
        }

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner

    function airDrop(address _to, uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply();
        require(_amount > 0);
        require(supply + _amount <= maxSupply);

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    // allowlist functions

    function enableWLSale() public onlyOwner {
        allowlistSale = true;
        cost = 0.05 ether;
    }

    function enablePublicSale() public onlyOwner {
        allowlistSale = false;
        cost = 0.075 ether;
    }

    function addAllowlistSpot(address to, uint256 _amount) external onlyOwner {
        allowlistSpots[to] += _amount;
    }

    function addAlowlistSpotsMultiple(
        address[] memory to,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(
            to.length == _amounts.length,
            "Different amount of addresses and spots"
        );
        uint256 total = 0;

        for (uint256 i = 0; i < to.length; ++i) {
            allowlistSpots[to[i]] += _amounts[i];
            total += _amounts[i];
        }
    }

    function isAllowlisted(address user, uint256 _amount) internal {
        require(allowlistSpots[user] >= _amount, "Exceeds whitelist spots");
        allowlistSpots[user] -= _amount;
    }

    // free claim functions

    function addFreeClaim(address to, uint256 _amount) external onlyOwner {
        freeClaims[to] += _amount;
    }

    function addFreeClaimsMultiple(
        address[] memory to,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(
            to.length == _amounts.length,
            "Different amount of addresses and spots"
        );
        uint256 total = 0;

        for (uint256 i = 0; i < to.length; ++i) {
            freeClaims[to[i]] += _amounts[i];
            total += _amounts[i];
        }
    }

    function isEligibleForClaim(address user, uint256 _amount) internal {
        require(freeClaims[user] >= _amount, "Exceeds free claims");
        freeClaims[user] -= _amount;
    }

    // Withdraws and Wallets

    function updateDaoWallet(address _newDao) public {
        require(msg.sender == dao, "Not authorized");
        dao = _newDao;
    }

    function updateDevWallet(address _newDev) public {
        require(msg.sender == dev, "Not authorized");
        dev = _newDev;
    }

    function updateArtistWallet(address _newArtist) public {
        require(msg.sender == artist, "Not authorized");
        artist = _newArtist;
    }

    function withdraw() external nonReentrant {
        require(
            owner() == msg.sender ||
                dao == msg.sender ||
                dev == msg.sender ||
                artist == msg.sender,
            "Not authorized"
        );
        uint256 balance = address(this).balance;
        payable(owner()).transfer((balance * 60) / 100); // 60%
        payable(dao).transfer((balance * 25) / 100); // 25%
        payable(dev).transfer((balance * 10) / 100); // 10%
        payable(artist).transfer((balance * 5) / 100); // 5%
    }
}