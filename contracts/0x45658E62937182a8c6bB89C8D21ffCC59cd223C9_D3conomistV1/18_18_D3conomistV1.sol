// SPDX-License-Identifier: UNLINCENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract D3conomistV1 is Initializable, ERC721Upgradeable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    uint256 public constant maxSupply = 2500;
    uint256 public constant VERSION = 1 ;
    uint256 public cost;
    string public uriPrefix;  

    event Minted(uint amount);

    modifier mintCompliance(uint256 _mintAmount) {
        require(_tokenIdCounter.current() + _mintAmount <= maxSupply, "Max supply exceeded");

        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("D3conomist", "D3");
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        cost = 0.25 ether;
        uriPrefix="ipfs://QmUQMXRgEgy34WS6x7hoBGZR4Jw2T4MFqHcz9vPmeZiB4m/";
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    
    function teamMint(address[] memory _to, uint[] memory _amount) public onlyOwner {
        require(_to.length == _amount.length, 'Recipients and IDs mismatch');
        for(uint i=0;i<_to.length; i++){
            require(_tokenIdCounter.current() + _amount[i] <= maxSupply, "Max supply exceeded");
            _mintLoop(_to[i], _amount[i]);
        }
    }

    function mint(uint256 _mintAmount ) public payable mintCompliance(_mintAmount) whenNotPaused{   
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        
        _mintLoop(msg.sender, _mintAmount);
        emit Minted(_mintAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return uriPrefix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json"))
            : "";
    }
    
    function _mintLoop(address _receiver, uint256 _mintAmount) private {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(_receiver, _tokenIdCounter.current());
        }
    }
}