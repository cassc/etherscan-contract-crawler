// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)
pragma solidity ^0.8.0;

import "../interfaces/IVariablePrice.sol";
import "../libraries/VariablePriceLib.sol";
import "../utilities/Modifiers.sol";

/**
 * @dev Enables the diamond to receiver erc1155 tokens. This contract also requires 
 * supportsInterface to support ERC721. This is implemenented in the DiamondInit contract.
 */
contract VariablePriceFacet is Modifiers {

    using VariablePriceLib for VariablePriceContract;

    function currentPrice() external view returns (uint256 _price) {
        VariablePriceContract storage ds = VariablePriceLib.variablePriceStorage().variablePrices;
        _price = ds._currentPrice();
    }

    function setPrice(uint256 _price) external onlyOwner {
        VariablePriceContract storage ds = VariablePriceLib.variablePriceStorage().variablePrices;
        ds._setPrice(_price);
    }
}