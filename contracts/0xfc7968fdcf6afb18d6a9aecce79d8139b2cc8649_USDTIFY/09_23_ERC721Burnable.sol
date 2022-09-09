// SPDX-License-Identifier: USDTIFY.com
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Context.sol";
abstract contract ERC721Burnable is Context, ERC721 {
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}