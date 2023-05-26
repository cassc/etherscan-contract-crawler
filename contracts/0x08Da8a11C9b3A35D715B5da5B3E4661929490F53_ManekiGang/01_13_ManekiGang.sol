pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract LuckyManeki {
    function ownerOfAux(uint256 tokenId) public virtual view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function baseURI() public virtual view returns (string memory);
    function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract ManekiGang is ERC721Enumerable, Ownable {

    string private _baseTokenURI;
    uint256 public MAX_SUPPLY;
    string public PROVENANCE;

    uint256 public revealOffset;
    LuckyManeki private lm;
    bool public saleStarted = false;

    constructor () 
        ERC721( "ManekiGang", "MKGG" )
    {
        _baseTokenURI = "https://maneki-gang.s3.amazonaws.com/meta/";
        MAX_SUPPLY = 14159;
        PROVENANCE = '';
        lm = LuckyManeki(0x14f03368B43E3a3D27d45F84FabD61Cc07EA5da3);
    }

    function claimOne(uint256 tokenId) external {
        require(saleStarted == true, "Sale has not started.");
        require(lm.ownerOfAux(tokenId) == (msg.sender), "!owner of maneki");
        require(totalSupply() < MAX_SUPPLY, "totalSupply > MAX_SUPPLY");
        _safeMint(msg.sender, tokenId);
    }

    function claimMany(uint256[] memory tokenIds) external {
        require(saleStarted == true, "Sale has not started.");
        require( tokenIds.length <= 40, "tokens > 40" );
        require(totalSupply() + tokenIds.length <= MAX_SUPPLY, "totalSupply > MAX_SUPPLY");

        for(uint i=0; i<tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            if(lm.ownerOfAux(tokenId) != (msg.sender)) {
                continue;
            }
            if (!_exists(tokenId)) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(revealOffset != 0, "!reveal");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!(owner|approved)");
        _burn(tokenId);
    }

    /* -- ADMIN -- */

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function reveal() public onlyOwner {
        /* Reveal ends the sale */
        require(revealOffset == 0, "!!reveal");
        saleStarted = false;
        revealOffset = uint256(blockhash(block.number - 1)) % MAX_SUPPLY;
    }

    function flipSaleState() public onlyOwner {
        /* Sale can only be paused/unpaused before reveal. */
        require(revealOffset == 0, "!!reveal");
        saleStarted = !saleStarted;
    }

    function setProvenance(string memory newProvenance) public onlyOwner {
        /* Provenance can only be changed before reveal. */
        require(revealOffset == 0, "!!reveal");
        PROVENANCE = newProvenance;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}