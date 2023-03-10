// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;

import { Ordinal } from "./BTC721.sol";

contract BTC721Helper
{
    // returns an array of ordinals corresponding to each tokenId
    // if inscriptionId is an empty string it has not been set
    function getAllOrdinals(
        IBTC721 _btc721Contract,
        uint256 _totalSupply
    ) public view returns (Ordinal[] memory){
        Ordinal[] memory ordinals = new Ordinal[](_totalSupply);
        for (uint256 i; i < _totalSupply; i++) {
            string memory id;
            uint256 num;
            (id, num) = _btc721Contract.tokenIdToOrdinal(i);
            ordinals[i] = Ordinal(id, num);
        }

        return ordinals;
    }

}

interface IBTC721 {
    function tokenIdToOrdinal(uint256 tokenId) external view returns (string memory, uint256);
}