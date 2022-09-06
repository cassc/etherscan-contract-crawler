// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface ILendPool {
    struct NftConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 56: NFT is active
        //bit 57: NFT is frozen
        uint256 data;
    }
    struct NftData {
        //stores the nft configuration
        NftConfigurationMap configuration;
        //address of the bNFT contract
        address bNftAddress;
        //the id of the nft. Represents the position in the list of the active nfts
        uint8 id;
    }

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral
     * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
     *   and lock collateral asset in contract
     * @param reserveAsset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token ID of the underlying NFT used as collateral
     * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function borrow(
        address reserveAsset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
     * - E.g. User repays 100 USDC, burning loan and receives collateral asset
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token ID of the underlying NFT used as collateral
     * @param amount The amount to repay
     * @return The final amount repaid, loan is burned or not
     **/
    function repay(
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    ) external returns (uint256, bool);

    /**
     * @notice Redeem a NFT loan which state is in Auction
     * - E.g. User repays 100 USDC, burning loan and receives collateral asset
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token ID of the underlying NFT used as collateral
     * @param amount The amount to repay the debt
     * @param bidFine The amount of bid fine
     **/
    function redeem(
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount,
        uint256 bidFine
    ) external returns (uint256);

    function getNftData(address asset) external view returns (NftData memory);

    /**
     * @dev Returns the debt data of the NFT
     * @param nftAsset The address of the NFT
     * @param nftTokenId The token id of the NFT
     * @return loanId the loan id of the NFT
     * @return reserveAsset the address of the Reserve
     * @return totalCollateral the total power of the NFT
     * @return totalDebt the total debt of the NFT
     * @return availableBorrows the borrowing power left of the NFT
     * @return healthFactor the current health factor of the NFT
     **/
    function getNftDebtData(address nftAsset, uint256 nftTokenId)
        external
        returns (
            uint256 loanId,
            address reserveAsset,
            uint256 totalCollateral,
            uint256 totalDebt,
            uint256 availableBorrows,
            uint256 healthFactor
        );

    /**
     * @dev Returns the auction data of the NFT
     * @param nftAsset The address of the NFT
     * @param nftTokenId The token id of the NFT
     * @return loanId the loan id of the NFT
     * @return bidderAddress the highest bidder address of the loan
     * @return bidPrice the highest bid price in Reserve of the loan
     * @return bidBorrowAmount the borrow amount in Reserve of the loan
     * @return bidFine the penalty fine of the loan
     **/
    function getNftAuctionData(address nftAsset, uint256 nftTokenId)
        external
        view
        returns (
            uint256 loanId,
            address bidderAddress,
            uint256 bidPrice,
            uint256 bidBorrowAmount,
            uint256 bidFine
        );
}