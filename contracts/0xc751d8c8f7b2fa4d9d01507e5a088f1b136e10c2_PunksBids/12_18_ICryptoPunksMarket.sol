// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICryptoPunksMarket {
    /**
     * @dev Buy a Punk for sale
     * @param punkIndex Punk Index
     */
    function buyPunk(uint256 punkIndex) external payable;

    /**
     * @dev Transfer a Punk to another wallet
     * @param to recipient address
     * @param punkIndex Punk Index
     */
    function transferPunk(address to, uint256 punkIndex) external;

    /**
     * @dev Retrieve owner address of a Punk
     * @param punkIndex Punk Index
     * @return The address of the Punk owner
     */
    function punkIndexToAddress(uint256 punkIndex) external view returns (address);

    /**
     * @dev Retrieve Punk sale details
     * @param _punkIndex Punk Index
     * @return isForSale True if the Punk is for sale
     * @return punkIndex Punk Index
     * @return seller Punk Owner
     * @return minValue Minimum value to be paid to buy the Punk
     * @return onlySellTo The only address that could buy the Punk (if not null address)
     */
    function punksOfferedForSale(uint256 _punkIndex)
        external
        view
        returns (bool isForSale, uint256 punkIndex, address seller, uint256 minValue, address onlySellTo);
}