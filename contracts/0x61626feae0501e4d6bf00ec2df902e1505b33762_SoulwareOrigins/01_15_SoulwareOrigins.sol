// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./WithdrawFairlyOrigin.sol";

contract SoulwareOrigins is ERC721Enumerable, Ownable, WithdrawFairlyOrigin {

    string public baseTokenURI;
    uint256 private constant MAX_SUPPLY = 101;

    constructor(string memory baseURI) ERC721("SoulwareOrigins", "SWO") WithdrawFairlyOrigin() {
        setBaseURI(baseURI);
    }

    function mintOriginForOpenSeaDutch(uint256 _count) public onlyOwner{
        for(uint256 i = 0; i < _count; i++){
            if(totalSupply() >= MAX_SUPPLY) break;
            _safeMint(owner(), totalSupply());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
}