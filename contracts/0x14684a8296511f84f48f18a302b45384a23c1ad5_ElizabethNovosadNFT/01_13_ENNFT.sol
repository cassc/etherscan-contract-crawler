// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ElizabethNovosadNFT is ERC721, Ownable, IERC2981 {
    uint256 constant ROYALTY_AMOUNT = 1000;
    error InvalidTokenId();

    constructor(address owner_, address gift_) ERC721("Elizabeth Novosad NFT", "EN") {
        for (uint8 i = 1; i < 19; i++) {
            if (i == 7) {
                _mint(gift_, i);    
            } else {
                _mint(owner_, i);
            }
        }
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 tokenSalePrice
    ) external view override returns (address royaltyReceiver, uint256 royaltyAmount) {
        if (tokenId < 0) revert InvalidTokenId();
        royaltyAmount = (tokenSalePrice * ROYALTY_AMOUNT) / 10000;
        return (owner(), royaltyAmount);
    }

    function _baseURI() internal view override returns (string memory) {
        return "ipfs://QmUebdHuaeFQGHTrfxCV64rWdPy11qqL8ctwWtzv14mB8Z/";
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId_), ".json"));
    }
}