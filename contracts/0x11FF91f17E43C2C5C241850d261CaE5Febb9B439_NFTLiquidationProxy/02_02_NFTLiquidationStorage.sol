// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract NFTLiquidationProxyStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of NFTLiquidationProxy
    */
    address public nftLiquidationImplementation;

    /**
    * @notice Pending brains of NFTLiquidationProxy
    */
    address public pendingNFTLiquidationImplementation;
}

contract NFTLiquidationV1Storage is NFTLiquidationProxyStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice Comptroller
     */
    address public comptroller;

    /**
     * @notice CEther
     */
    address public cEther;

    /**
     * @notice Protocol Fee Recipient
     */
    address payable public protocolFeeRecipient;

    /**
     * @notice Protocol Fee
     */
    uint256 public protocolFeeMantissa;

    /**
     * @notice Extra repay amount(unit is main repay token)
     */
    uint256 public extraRepayAmount;

    /**
     * @notice Requested seize NFT index array
     */
    uint256[] public seizeIndexes_;
}