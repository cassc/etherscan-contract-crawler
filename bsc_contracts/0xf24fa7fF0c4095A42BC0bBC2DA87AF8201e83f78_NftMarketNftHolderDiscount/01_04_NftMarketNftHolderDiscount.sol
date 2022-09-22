// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../includes/interfaces/IRugZombieNft.sol";
import "../includes/access/Ownable.sol";

contract NftMarketNftHolderDiscount is Ownable {
    IRugZombieNft   public nft;        // The NFT providing the discount

    // Constructor for initializing the contract
    constructor(address _nft) {
        nft = IRugZombieNft(_nft);
    }

    // Function to check if the user is illegible for discount
    function isApplicable(address _user) public view returns (bool) {
        return nft.balanceOf(_user) > 0;
    }
}