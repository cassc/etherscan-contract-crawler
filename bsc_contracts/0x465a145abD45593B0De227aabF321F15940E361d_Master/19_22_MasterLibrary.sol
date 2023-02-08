// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Mintingocollection.sol";

library MasterLibrary{

  function  lib_create_collection(
        string memory _name,
        string memory _symbol, uint256[] memory totalClaimable, uint[] memory tiers, address[] memory coins, uint256[] memory amounts, address[] memory coin_to_pay, address[] memory nfts, uint256[] memory price_to_pay , address owner) external returns(address) {
        MintingoCollection collection = new MintingoCollection(_name, _symbol, totalClaimable, tiers, coins, amounts, coin_to_pay, nfts, price_to_pay, owner);
        address collection_address = address(collection);

        return collection_address;
    }


}