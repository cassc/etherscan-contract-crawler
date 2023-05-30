// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./IDAMA.sol";
import "./INewKinko.sol";

contract YakuzaCatsSocietyTheKillers is
    ERC721Enumerable,
    ReentrancyGuard,
    Ownable
{
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant KAMI = 0x001094B68DBAD2dce5E72d3F13A4ACE2184AE4B7;
    address public constant YCS = 0x454cBC099079DC38b145E37e982e524AF3279c44;
    address public constant DAMA = 0x2C0da41C89AdB5a1d4430E5761b9B400911426B0;
    address public KINKO;

    uint256 public constant UNIT_PRICE = 600 ether;
    mapping(uint256 => uint256) public recruitCounts;
    uint256[] priceIncrease = [1, 2, 3, 5, 8, 13, 21];

    constructor() ERC721("Yakuza Cats Society - The Killers", "YCSK") {
        transferOwnership(KAMI);
    }

    function setKinko(address kinko) public onlyOwner {
        KINKO = kinko;
    }

    function getRecruitPrice(uint256 tokenId1, uint256 tokenId2)
        public
        view
        returns (uint256)
    {
        return
            UNIT_PRICE *
            (priceIncrease[recruitCounts[tokenId1]] +
                priceIncrease[recruitCounts[tokenId2]]);
    }

    function recruit(uint256 tokenId1, uint256 tokenId2) public nonReentrant {
        require(
            recruitCounts[tokenId1] < priceIncrease.length &&
                recruitCounts[tokenId2] < priceIncrease.length,
            "Exceeded count of recruiting"
        );
        if (KINKO == address(0)) {
            require(
                ERC721Enumerable(YCS).ownerOf(tokenId1) == msg.sender &&
                    ERC721Enumerable(YCS).ownerOf(tokenId2) == msg.sender,
                "Not Your Tokens"
            );
        } else {
            require(
                (ERC721Enumerable(YCS).ownerOf(tokenId1) == msg.sender ||
                    INewKinko(KINKO).ownerOf(YCS, msg.sender, tokenId1)) &&
                    (ERC721Enumerable(YCS).ownerOf(tokenId2) == msg.sender ||
                        INewKinko(KINKO).ownerOf(YCS, msg.sender, tokenId2)),
                "Not Your Tokens"
            );
        }

        uint256 recruitPrice = getRecruitPrice(tokenId1, tokenId2);
        uint256 minted = totalSupply();
        recruitCounts[tokenId1] += 1;
        recruitCounts[tokenId2] += 1;
        _safeMint(msg.sender, minted);
        IDAMA(DAMA).burn(msg.sender, recruitPrice);
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
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
        if (tokenId > 19999) {
            return string(abi.encodePacked("ipfs://QmTBNctprfyCxS6p8tuapVgMtLmcBgHVa5TkxP9q3ohak2/", tokenId.toString()));
        } else if (tokenId > 9999) {
            return string(abi.encodePacked("ipfs://QmRNqzjNgG9Q5tQjBCaxwkmnYU6JaUeG69uFuSBrvc91QF/", tokenId.toString()));
        } else {
            return string(abi.encodePacked("ipfs://QmNdhFRHTpQJp37Xy6KDGxbzSmwjpjehv6ahYNik1ChgYR/", tokenId.toString()));
        }
    }
}