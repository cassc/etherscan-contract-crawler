// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

interface IAristocratContract {
    function balanceOf(address owner) external returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        returns (uint256);
}

contract GTRHVNUC is Ownable, ReentrancyGuard, ERC721A {
    uint256 public immutable maxMint;
    uint256 public aristocratSupply = 3000;
    IAristocratContract private aristocratSC =
        IAristocratContract(0x13e1c9123DdE5334E8c2B24DB9F2Dc16f5673DE6);
    uint256 public mainSupply = 7777;
    uint256 public publicSupply = mainSupply - aristocratSupply;
    uint256 public mainPrice = 0.027 ether;
    string private _baseTokenURI;
    bool public mintLive = false;

    mapping(uint256 => bool) public isMinted;

    constructor(uint256 maxMint_, string memory baseTokenURI_)
        ERC721A("GTRHVNUC", "GTRHVNUC", maxMint_)
    {
        maxMint = maxMint_;
        _baseTokenURI = baseTokenURI_;
    }

    modifier publicRules(uint256 _mintCount) {
        require(_mintCount > 0, "Invalid mint amount!");
        require(publicSupply > 0, "Sold Out");
        require(publicSupply - _mintCount >= 0, "Max supply exceeded!");
        require(msg.value >= mainPrice * _mintCount, "Insufficient funds!");
        _;
    }

    function publicMint(uint256 _mintCount)
        external
        payable
        publicRules(_mintCount)
    {
        require(mintLive, "Mint is not open yet");
        publicSupply -= _mintCount;
        _safeMint(msg.sender, _mintCount);
    }

    function aristocratMint() external {
        require(mintLive, "Mint is not open yet");
        uint256 ownedRing = aristocratSC.balanceOf(msg.sender);
        uint256 _ringWorth = 0;
        uint256 i = 0;
        while (i < ownedRing) {
            uint256 _tokenId = aristocratSC.tokenOfOwnerByIndex(msg.sender, i);
            i++;
            if (!isMinted[_tokenId]) {
                if (_ringWorth < maxMint) {
                    isMinted[_tokenId] = true;
                    _ringWorth++;
                } else {
                    ownedRing = maxMint;
                    break;
                }
            }
        }
        require(_ringWorth > 0, "You need to have at least 1 ring available to claim");
        require(aristocratSupply > 0, "You need to have at least 1 ring available to claim");
        require(aristocratSupply - _ringWorth >= 0, "You need to have at least 1 ring available to claim");
        aristocratSupply -= _ringWorth;
        _safeMint(msg.sender, _ringWorth);
    }

    function setMintPrice(uint256 _mainPrice) external onlyOwner {
        mainPrice = _mainPrice;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function toggleSale() external onlyOwner {
        mintLive = !mintLive;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}