// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @author @inetdave
* @dev v.01.00.00
*/
contract GenkiBase is ReentrancyGuard, Ownable {

    enum ContractState {
        PAUSED,
        BID,
        WHITELIST,
        PUBLIC
    }

    ContractState public contractState = ContractState.PAUSED;

    uint256 public constant MAX_SUPPLY = 8000;
    uint256 public constant MAX_PER_PRIVATE_WALLET = 1;
    uint256 public constant MAX_PER_TX = 2;

    uint256 public maxBidSupply = 2500;

    uint256 public price;
    uint256 public discountedPrice;
    uint256 public OGPrice;

    address internal constant ANGEL_INVESTOR = 0x200083b855baab7607cB07d67cB6380B487807cc;
    address internal constant VOID_ZERO = 0x2f370e211B6EB193A13F6F92D49557Ba630Da86c;
    address internal constant OWNER = 0x0367e5800F7011f008143E453e8F7AD36A85c350;
    
    bool internal _hasPaidLumpSum;

    /**@notice set contract state
     * @param _contractState set the state of the contract
     */
    function _setContractState(ContractState _contractState) internal 
    {
        if (_contractState == ContractState.BID) {
            require(price == 0, "Price set");
        } else if (_contractState == ContractState.WHITELIST) {
            require(discountedPrice != 0, "Discount missing");
        } else if (_contractState == ContractState.PUBLIC) {
            require(price != 0, "Price missing");
        }
        contractState = _contractState;
    }
    /**
     * @notice set the clearing price and the discounted price for wl after all bids have been placed.
     * @dev set this price in wei, not eth! Can't set price if bidding is active
     * @param _price new price, set in wei
     * @param _discountedPrice new price, set in wei
     * @param _OGPrice new price, set in wei
     */
    function _setPrices(uint256 _price, uint256 _discountedPrice, uint256 _OGPrice) internal 
    {
        require(contractState != ContractState.BID, "Bidding active");
        price = _price;
        discountedPrice = _discountedPrice;
        OGPrice = _OGPrice;
    }

}