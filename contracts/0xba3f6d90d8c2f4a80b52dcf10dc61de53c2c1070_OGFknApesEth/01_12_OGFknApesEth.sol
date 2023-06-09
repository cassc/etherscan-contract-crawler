// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OGFknApesEth is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private counterObj;

    uint256 public cost = 100 ether;
    uint256 public maxSupply = 1501;
    uint256 public maxMintAmountPerTx = 500;

    bool public pauseOfMint = false;

    // Token status

    string public baseMetaPrefix = "https://fknapesclub.com/first_gen/meta/";

    constructor() ERC721("OG Fkn Apes", "OGFA") {}

    modifier isPossibleMint(uint256 mintAmount) {
        require(mintAmount > 0 && mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(counterObj.current() + mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    modifier existsToken(uint256 tokenId) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        _;
    }

    // tokenURI
    function setBaseMetaPrefix(string memory metaPrefix) public onlyOwner {
        baseMetaPrefix = metaPrefix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseMetaPrefix;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), '.json'));
    }

    // Supply
    function getTotalSupply() public view returns (uint256) {
        return counterObj.current();
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    // Mint
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setPauseOfMint(bool _state) public onlyOwner {
        pauseOfMint = _state;
    }


    // Mint
    function mint(uint256 mintAmount) public payable isPossibleMint(mintAmount) {
        require(!pauseOfMint, "The contract is paused!");
        require(msg.value >= cost * mintAmount, "Insufficient funds!");

        _mintLoop(_msgSender(), mintAmount);
    }

    function mintForAddress(address _addr, uint256 mintAmount) public isPossibleMint(mintAmount) onlyOwner {
        _mintLoop(_addr, mintAmount);
    }

    function _mintLoop(address _addr, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            counterObj.increment();
            _safeMint(_addr, counterObj.current() - 1);
        }
    }

    // misc
    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function getTokensByOwner(address _addr) public view returns (uint256[] memory) {
        uint256[] memory ownTokens = new uint256[](balanceOf(_addr));
        uint256 tokenId = 0;
        uint256 indx = 0;

        while (tokenId < counterObj.current()) {
            if (_exists(tokenId) && ownerOf(tokenId) == _addr) {
                ownTokens[indx] = tokenId;
                indx++;
            }
            tokenId++;
        }

        return ownTokens;
    }

    function withdraw() public onlyOwner {
        (bool os,) = payable(owner()).call{value : address(this).balance}("");
        require(os);
    }

}