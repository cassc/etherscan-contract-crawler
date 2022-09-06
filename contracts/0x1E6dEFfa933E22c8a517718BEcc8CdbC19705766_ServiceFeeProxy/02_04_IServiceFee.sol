// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

/**
 * @notice Service Fee interface for Ikonic NFT Marketplace 
 */
interface IServiceFee {

    /**
     * @notice Admin can add proxy address
     * @param _proxyAddr address of proxy
     */
    function addProxy(address _proxyAddr) external;

    /**
     * @notice Admin can remove proxy address
     * @param _proxyAddr address of proxy
     */
    function removeProxy(address _proxyAddr) external;

    /**
     * @notice Calculate the seller service fee
     */
    function getSellServiceFeeBps() external view returns (uint256);

    /**
     * @notice Calculate the buyer service fee
     */
    function getBuyServiceFeeBps() external view returns (uint256);

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() external view returns (address);

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address _serviceFeeRecipient) external;

    /**
     * @notice Set seller service fee
     * @param _sellerFee seller service fee
     */
    function setSellServiceFee(uint256 _sellerFee) external;

    /**
     * @notice Set buyer service fee
     * @param _buyerFee buyer service fee
     */
    function setBuyServiceFee(uint256 _buyerFee) external; 
}