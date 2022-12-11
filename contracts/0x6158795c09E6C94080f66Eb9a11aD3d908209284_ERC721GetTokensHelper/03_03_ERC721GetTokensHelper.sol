// SPDX-License-Identifier: MIT
// lostparadigms.xyz
// mikemikemike (https://twitter.com/0xmikemikemike)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721GetTokensHelper {
    /*
     *   Helper function that returns an array of all tokens held in an ERC721 contract by a 
     *   given address. This function should only be called offchain as it is gas intensive.
     *   
     *   Assumptions - ERC721 contract has tokens minted in consequtive order from any starting index
     *
     *   Params:
     *   IERC721 _erc721Contract - ERC721 contract
     *   address _address - wallet address of token holder
     *   uint256 _startIndex - starting index (some ERC721 tokens start 
     *                         mint from 0 , some start from 1)
     *   uint256 _totalSupply - total supply of ERC721
     */
    function getTokens(
        IERC721 _erc721Contract,
        address _address,
        uint256 _startIndex,
        uint256 _totalSupply
    ) public view returns (uint256[] memory){
        uint256[] memory tokenIdsHeld = new uint256[](_erc721Contract.balanceOf(_address));
        uint256 tokenIdsHeldIndex;

        for (uint256 i = _startIndex; i < _totalSupply; i++) {
            if (_erc721Contract.ownerOf(i) == _address) {
                tokenIdsHeld[tokenIdsHeldIndex] = i;
                tokenIdsHeldIndex++;
            }
        }

        return tokenIdsHeld;
    }
}