/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../libraries/OrderLib.sol";

/**
 * @title  Alkimiya Swap Proxy Interface
 * @author Alkimiya Team
 * @notice This is the interface for Swap Proxy contract
 * */
interface ISwapProxy {

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    // MatcherAddress is set to Vault if order is filled onbehalf of vault by admin/trader
    event SellOrderFilled(address silicaAddress, bytes32 orderHash, address signerAddress, address matcherAddress, uint256 purchaseAmount);

    event BuyOrderFilled(address silicaAddress, bytes32 orderHash, address signerAddress, address matcherAddress, uint256 purchaseAmount);

    event SellOrderCancelled(address signerAddress, bytes32 orderHash);

    event BuyOrderCancelled(address signerAddress, bytes32 orderHash);

    /*///////////////////////////////////////////////////////////////
                             Functionality
    //////////////////////////////////////////////////////////////*/

    function domainSeparator() external view returns (bytes32);

    function setSilicaFactory(address _silicaFactoryAddress) external;

    /// @param purchaseAmount - in resource units e.g. H/s
    /// @param additionalCollateralPercent - added on top of base 10%,
    ///        e.g. if `additionalCollateralPercent = 20` then seller will
    ///        put 30% collateral.
    function fillBuyOrder(
        OrderLib.BuyOrder calldata buyerOrder,
        bytes memory buyerSignature,
        uint256 purchaseAmount,
        uint256 additionalCollateralPercent
    ) external returns (address);

    function fillSellOrder(
        OrderLib.SellOrder calldata sellerOrder,
        bytes memory sellerSignature,
        uint256 amount
    ) external returns (address);

    function routeBuy(
        OrderLib.SellOrder calldata sellerOrder,
        bytes memory sellerSignature,
        uint256 amount
    ) external returns (address);

    /// @notice Function to check if an order is canceled
    function isBuyOrderCancelled(bytes32 orderHash) external view returns (bool);

    function isSellOrderCancelled(bytes32 orderHash) external view returns (bool);

    /// @notice Function to return budget consumed by a buy order
    function getBudgetConsumedFromOrderHash(bytes32 orderHash) external view returns (uint256);

    /// @notice Function to return the Silica Address created from a sell order
    function getSilicaAddressFromSellOrderHash(bytes32 orderHash) external view returns (address);

    function cancelBuyOrder(OrderLib.BuyOrder calldata order, bytes memory signature) external;

    function cancelSellOrder(OrderLib.SellOrder calldata order, bytes memory signature) external;

    // function fillSellOrderAsVault(
    //     OrderLib.SellOrder calldata sellerOrder,
    //     bytes memory sellerSignature,
    //     uint256 amount,
    //     address vaultAddress
    // ) external returns (address);
}