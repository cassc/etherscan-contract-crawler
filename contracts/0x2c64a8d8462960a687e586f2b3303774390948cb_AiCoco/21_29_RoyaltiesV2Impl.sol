// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AbstractRoyalties.sol";
import "../RoyaltiesV2.sol";
import "../IERC2981.sol";
import "../LibRoyalties2981.sol";

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2, IERC2981 {

    function getRaribleV2Royalties(uint256 _tokenId) override external view returns (LibPart.Part[] memory) {
        return royalties[_tokenId];
    }

    function _onRoyaltiesSet(uint256 _tokenId, LibPart.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(_tokenId, _royalties);
    }

    /*
    *Token (ERC721, ERC721Minimal, ERC721MinimalMeta, ERC1155 ) can have a number of different royalties beneficiaries
    *calculate sum all royalties, but royalties beneficiary will be only one royalties[0].account, according to rules of IERC2981
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) override external view returns (address receiver, uint256 royaltyAmount) {
        if (royalties[_tokenId].length == 0) {
            receiver = address(0);
            royaltyAmount = 0;
            return(receiver, royaltyAmount);
        }
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        receiver = _royalties[0].account;
        uint percent;
        for (uint i = 0; i < _royalties.length; ++i) {
            percent += _royalties[i].value;
        }
        //don`t need require(percent < 10000, "Token royalty > 100%"); here, because check later in calculateRoyalties
        royaltyAmount = percent * _salePrice / 10000;
    }
}