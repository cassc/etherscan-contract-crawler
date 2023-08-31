/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
 * */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library OrderLib {

    /*///////////////////////////////////////////////////////////////
                             State Variables
    //////////////////////////////////////////////////////////////*/

    enum OrderType {
        SellerOrder, //0
        BuyerOrder   //1
    }

    struct BuyOrder {
        uint8 commodityType;
        uint32 endDay;
        uint32 orderExpirationTimestamp;
        uint32 salt;
        uint256 resourceAmount;
        uint256 unitPrice;
        address signerAddress;
        address rewardToken;
        address paymentToken;
        address vaultAddress;
    }

    struct SellOrder {
        uint8 commodityType;
        uint32 endDay;
        uint32 orderExpirationTimestamp;
        uint32 salt;
        uint256 resourceAmount;
        uint256 unitPrice;
        address signerAddress;
        address rewardToken;
        address paymentToken;
        uint256 additionalCollateralPercent;
    }
    
    // Constants

    bytes32 public constant BUY_ORDER_TYPEHASH =
        keccak256(
            "BuyOrder(uint8 commodityType,uint32 endDay,uint32 orderExpirationTimestamp,uint32 salt,uint256 resourceAmount,uint256 unitPrice,address signerAddress,address rewardToken,address paymentToken,address vaultAddress)"
        );

    bytes32 public constant SELL_ORDER_TYPEHASH =
        keccak256(
            "SellOrder(uint8 commodityType,uint32 endDay,uint32 orderExpirationTimestamp,uint32 salt,uint256 resourceAmount,uint256 unitPrice,address signerAddress,address rewardToken,address paymentToken,uint256 additionalCollateralPercent)"
        );

    /*///////////////////////////////////////////////////////////////
                            Functionailty 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to get the hash of a Buy Order
     * @param order Instance of the BuyOrder struct({
     *      commodityType:
     *      endDay:
     *      orderExpirationTimestamp:
     *      salt:
     *      resourceAmount:
     *      unitPrice:
     *      signerAddress:
     *      rewardToken:
     *      paymentToken:
     *      vaultAddress: 
     * })
     * @return bytes32: Hash of the Buy Order
     */
    function _getBuyOrderHash(OrderLib.BuyOrder memory order) internal pure returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                OrderLib.BUY_ORDER_TYPEHASH,
                order.commodityType,
                order.endDay,
                order.orderExpirationTimestamp,
                order.salt,
                order.resourceAmount,
                order.unitPrice,
                order.signerAddress,
                order.rewardToken,
                order.paymentToken,
                order.vaultAddress
            )
        );

        return structHash;
    }

    /**
     * @notice Function to get the hash of a Sell Order
     * @param order Instance of the SellOrder struct({
     *      commodityType:
     *      endDay:
     *      orderExpirationTimestamp:
     *      salt:
     *      resourceAmount:
     *      unitPrice:
     *      signerAddress:
     *      rewardToken:
     *      paymentToken:
     *      additionalCollateralPercent: 
     * })
     * @return bytes32: Hash of the Sell Order
     */
    function _getSellOrderHash(OrderLib.SellOrder memory order) internal pure returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                OrderLib.SELL_ORDER_TYPEHASH,
                order.commodityType,
                order.endDay,
                order.orderExpirationTimestamp,
                order.salt,
                order.resourceAmount,
                order.unitPrice,
                order.signerAddress,
                order.rewardToken,
                order.paymentToken,
                order.additionalCollateralPercent
            )
        );

        return structHash;
    }

    /**
     * @notice Function to get the typed data hash of a Buy Order
     * @param  _order Instance of the BuyOrder struct({
     *      commodityType:
     *      endDay:
     *      orderExpirationTimestamp:
     *      salt:
     *      resourceAmount:
     *      unitPrice:
     *      signerAddress:
     *      rewardToken:
     *      paymentToken:
     *      vaultAddress: 
     * })
     * @param DOMAIN_SEPARATOR The EIP721 separator 
     * @return bytes32: Hash of the Buy Order
     */
    function _getTypedDataHash(OrderLib.BuyOrder memory _order, bytes32 DOMAIN_SEPARATOR) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _getBuyOrderHash(_order)));
    }

    /**
     * @notice Function to get the typed data hash of a Sell Order
     * @param  _order Instance of the SellOrder struct({
     *      commodityType:
     *      endDay:
     *      orderExpirationTimestamp:
     *      salt:
     *      resourceAmount:
     *      unitPrice:
     *      signerAddress:
     *      rewardToken:
     *      paymentToken:
     *      additionalCollateralPercent: 
     * })
     * @param DOMAIN_SEPARATOR The EIP721 separator 
     * @return bytes32: Hash of the Sell Order
     */
    function _getTypedDataHash(OrderLib.SellOrder memory _order, bytes32 DOMAIN_SEPARATOR) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _getSellOrderHash(_order)));
    }
}