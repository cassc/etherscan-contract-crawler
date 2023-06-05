//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "../structures/dOTCManagerStruct.sol";

/**
 * @title Interface for dOTCManager
 * @author Swarm
 */
interface IdOTC {
    /**
     * @dev Returns the address of the maker
     *
     * @param offerId uint256 the Id of the order
     *
     * @return maker address
     * @return cpk address
     */
    function getOfferOwner(uint256 offerId) external view returns (address maker, address cpk);

    /**
     * @dev Returns the dOTCOffer Struct of the offerId
     *
     * @param offerId uint256 the Id of the offer
     *
     * @return offer dOTCOffer
     */
    function getOffer(uint256 offerId) external view returns (dOTCOffer memory offer);

    /**
     * @dev Returns the address of the taker
     *
     * @param orderId uint256 the id of the order
     *
     * @return taker address
     */
    function getTaker(uint256 orderId) external view returns (address taker);

    /**
     * @dev Returns the Order Struct of the oreder_id
     *
     * @param orderId uint256
     *
     * @return order Order
     */
    function getTakerOrders(uint256 orderId) external view returns (Order memory order);
}