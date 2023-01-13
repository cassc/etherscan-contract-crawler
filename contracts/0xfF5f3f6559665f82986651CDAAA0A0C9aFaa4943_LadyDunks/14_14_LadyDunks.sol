// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

abstract contract DUNK {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract LadyDunks is ERC721Enumerable, Ownable {

    DUNK private dunk = DUNK(0xf21d1B31b15282592Ff0E48f7b474B57AE418361);
    bool public saleIsActive = false;
    uint256 public maxLDUNK = 2500;
    string private baseURI;
    uint256 public startingIndex;
    uint256 public startingIndexBlock;
    uint256 public setBlockTimestamp;

    constructor() ERC721("Lady Dunks", "LDUNK") {
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        require(tokenId < maxLDUNK, "tokenId outside collection bounds");
        return _exists(tokenId);
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function trySetStartingIndexBlock() private {
        if ( startingIndexBlock == 0 && (totalSupply() == maxLDUNK || block.timestamp >= setBlockTimestamp)) {
            startingIndexBlock = block.number;
        }
    }

    function setStartingBlockTimestamp(uint256 startingBlockTimestamp) public onlyOwner {
        setBlockTimestamp = startingBlockTimestamp;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    function mintLDUNK(uint256 dunkTokenId) public {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() < maxLDUNK, "Purchase would exceed max ");
        require(dunkTokenId < maxLDUNK, "Requested tokenId exceeds upper bound");
        require(dunk.ownerOf(dunkTokenId) == msg.sender, "Must own the Dunk for requested tokenId to claim a LDUNK");

        _safeMint(msg.sender, dunkTokenId);
        trySetStartingIndexBlock();
    }
}