// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../includes/interfaces/IRugZombieNft.sol";
import "../includes/access/Ownable.sol";

interface IWhalePool {
    function checkUserStaked(address _user) external view returns(bool);
}

contract NftMarketWhalepoolDiscount is Ownable {
    IRugZombieNft   public whaleNft;        // The current whale pass season NFT
    IWhalePool      public whalePool;       // The whale pool

    // Constructor for initializing the contract
    constructor(address _whaleNft, address _whalePool) {
        whaleNft = IRugZombieNft(_whaleNft);
        whalePool = IWhalePool(_whalePool);
    }

    // Function for the owner to set the whale NFT
    function setWhaleNft(address _whaleNft) public onlyOwner() {
        whaleNft = IRugZombieNft(_whaleNft);
    }

    // Function for the owner to set the whale pool
    function setWhalePool(address _whalePool) public onlyOwner() {
        whalePool = IWhalePool(_whalePool);
    }

    // Function to check if the user is eligiable for current discounts
    function isApplicable(address _user) public view returns (bool) {
        if (whaleNft.balanceOf(_user) > 0) return true;
        return whalePool.checkUserStaked(_user);
    }
}