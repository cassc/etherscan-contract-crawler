// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface to jpeg'd NFTVault Contracts
 * @dev https://github.com/jpegd/core/blob/main/contracts/vaults/NFTVault.sol
 */
interface INFTVault {
    /// jpeg'd RATE struct
    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    /// jpeg'd vault settings struct
    struct VaultSettings {
        Rate debtInterestApr;
        Rate creditLimitRate;
        Rate liquidationLimitRate;
        Rate cigStakedCreditLimitRate;
        Rate cigStakedLiquidationLimitRate;
        /// @custom:oz-renamed-from valueIncreaseLockRate
        Rate unused12;
        Rate organizationFeeRate;
        Rate insurancePurchaseRate;
        Rate insuranceLiquidationPenaltyRate;
        uint256 insuranceRepurchaseTimeLimit;
        uint256 borrowAmountCap;
    }

    /// jpeg'd vault BorrowType enum
    enum BorrowType {
        NOT_CONFIRMED,
        NON_INSURANCE,
        USE_INSURANCE
    }

    /// jpeg'd vault Position struct
    struct Position {
        BorrowType borrowType;
        uint256 debtPrincipal;
        uint256 debtPortion;
        uint256 debtAmountForRepurchase;
        uint256 liquidatedAt;
        address liquidator;
    }

    /// @notice Allows users to open positions and borrow using an NFT
    /// @dev emits a {Borrowed} event
    /// @param _nftIndex The index of the NFT to be used as collateral
    /// @param _amount The amount of PUSD to be borrowed. Note that the user will receive less than the amount requested,
    /// the borrow fee and insurance automatically get removed from the amount borrowed
    /// @param _useInsurance Whether to open an insured position. In case the position has already been opened previously,
    /// this parameter needs to match the previous insurance mode. To change insurance mode, a user needs to close and reopen the position
    function borrow(
        uint256 _nftIndex,
        uint256 _amount,
        bool _useInsurance
    ) external;

    /// @param _nftIndex The NFT to return the value of
    /// @return The value in USD of the NFT at index `_nftIndex`, with 18 decimals.
    function getNFTValueUSD(uint256 _nftIndex) external view returns (uint256);

    /// @param _nftIndex The NFT to return the credit limit of
    /// @return The PETH/PUSD credit limit of the NFT at index `_nftIndex`.
    function getCreditLimit(
        address _owner,
        uint256 _nftIndex
    ) external view returns (uint256);

    /**
     * @notice getter for jpegdVault settings
     * @return VaultSettings settings of jpegdVault
     */
    function settings() external view returns (VaultSettings memory);

    /**
     * @notice getter for owned of position opened in jpegdVault
     * @param tokenId NFT id mapping to position owner
     * @return address position owner address
     */
    function positionOwner(uint256 tokenId) external view returns (address);

    /// @param _nftIndex The NFT to check
    /// @return The PUSD debt interest accumulated by the NFT at index `_nftIndex`.
    function getDebtInterest(uint256 _nftIndex) external view returns (uint256);

    /// @return The floor value for the collection, in ETH.
    function getFloorETH() external view returns (uint256);

    /// @notice Allows users to repay a portion/all of their debt. Note that since interest increases every second,
    /// a user wanting to repay all of their debt should repay for an amount greater than their current debt to account for the
    /// additional interest while the repay transaction is pending, the contract will only take what's necessary to repay all the debt
    /// @dev Emits a {Repaid} event
    /// @param _nftIndex The NFT used as collateral for the position
    /// @param _amount The amount of debt to repay. If greater than the position's outstanding debt, only the amount necessary to repay all the debt will be taken
    function repay(uint256 _nftIndex, uint256 _amount) external;

    /// @notice Allows a user to close a position and get their collateral back, if the position's outstanding debt is 0
    /// @dev Emits a {PositionClosed} event
    /// @param _nftIndex The index of the NFT used as collateral
    function closePosition(uint256 _nftIndex) external;

    /**
     * @notice getter for position corresponding to tokenId
     * @param tokenId NFT id mapping to position
     * @return position corresponding to tokenId
     */
    function positions(uint256 tokenId) external view returns (Position memory);

    /**
     * @notice getter for total globabl debt in jpeg'd vault
     * @return uin256 total global debt
     */
    function totalDebtAmount() external view returns (uint256);

    /**
     * @notice getter for the JPEG'd NFT Value provider contract address
     * @return address of NFT Value provider
     */
    function nftValueProvider() external view returns (address);

    /// @param _nftIndex The NFT to return the liquidation limit of
    /// @return The PETH liquidation limit of the NFT at index `_nftIndex`.
    function getLiquidationLimit(
        address _owner,
        uint256 _nftIndex
    ) external view returns (uint256);

    /**
     * @notice returns underlying stablecoin (PETH/PUSD) of NFT Vault
     * @return coin address of PETH/PUSD
     */
    function stablecoin() external view returns (address coin);

    /**
     * @notice returns underlying ERC721 collection of NFT Vault
     * @return collection ERC721 collection address
     */
    function nftContract() external view returns (address collection);
}