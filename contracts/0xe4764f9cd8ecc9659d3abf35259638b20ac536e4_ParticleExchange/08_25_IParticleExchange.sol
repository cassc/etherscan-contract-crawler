// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Lien} from "../libraries/types/Structs.sol";

interface IParticleExchange {
    event SupplyNFT(uint256 lienId, address lender, address collection, uint256 tokenId, uint256 price, uint256 rate);

    event UpdateLoan(uint256 lienId, uint256 price, uint256 rate);

    event WithdrawNFT(uint256 lienId);

    event WithdrawETH(uint256 lienId);

    event SellMarketNFT(uint256 lienId, address borrower, uint256 soldAmount, uint256 loanStartTime);

    event BuyMarketNFT(uint256 lienId, uint256 tokenId, uint256 paidAmount);

    event SwapWithETH(uint256 lienId, address borrower, uint256 loanStartTime);

    event RepayWithNFT(uint256 lienId, uint256 tokenId);

    event Refinance(uint256 oldLienId, uint256 newLienId, uint256 loanStartTime);

    event OfferBid(uint256 lienId, address borrower, address collection, uint256 margin, uint256 price, uint256 rate);

    event UpdateBid(uint256 lienId, uint256 margin, uint256 price, uint256 rate);

    event CancelBid(uint256 lienId);

    event AcceptBid(uint256 lienId, address lender, uint256 tokenId, uint256 soldAmount, uint256 loanStartTime);

    event StartAuction(uint256 lienId, uint256 auctionStartTime);

    event StopAuction(uint256 lienId);

    event AuctionSellNFT(uint256 lienId, address supplier, uint256 tokenId, uint256 paidAmount);

    event AccrueInterest(address account, uint256 amount);

    event WithdrawAccountBalance(address account, uint256 amount);

    event UpdateTreasuryRate(uint256 rate);

    event WithdrawTreasury(address receiver, uint256 amount);

    event RegisterMarketplace(address marketplace);

    event UnregisterMarketplace(address marketplace);

    /*==============================================================
                                Supply Logic
    ==============================================================*/

    /**
     * @notice Supply an NFT to contract
     * @param collection The address to the NFT collection
     * @param tokenId The ID of the NFT being supplied
     * @param price The supplier specified price for NFT
     * @param rate The supplier specified interest rate
     * @return lienId newly generated lienId
     */
    function supplyNft(
        address collection,
        uint256 tokenId,
        uint256 price,
        uint256 rate
    ) external returns (uint256 lienId);

    /**
     * @notice Update Loan parameters
     * @param lien Reconstructed lien info
     * @param lienId The ID for the existing lien
     * @param price The supplier specified new price for NFT
     * @param rate The supplier specified new interest rate
     */
    function updateLoan(Lien calldata lien, uint256 lienId, uint256 price, uint256 rate) external;

    /*==============================================================
                              Withdraw Logic
    ==============================================================*/

    /**
     * @notice Withdraw NFT from the contract
     * @param lien Reconstructed lien info
     * @param lienId The ID for the lien being cleared
     */
    function withdrawNft(Lien calldata lien, uint256 lienId) external;

    /**
     * @notice Withdraw ETH from the contract
     * @param lien Reconstructed lien info
     * @param lienId The ID for the lien being cleared
     */
    function withdrawEth(Lien calldata lien, uint256 lienId) external;

    /**
     * @notice Withdraw account balance of the message sender account
     */
    function withdrawAccountBalance() external;

    /*==============================================================
                               Trading Logic
    ==============================================================*/

    /**
     * @notice Pull-based sell NFT to market (another contract initiates NFT transfer)
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     * @param amount Declared ETH amount for NFT sale
     * @param marketplace The contract address of the marketplace (e.g. Seaport Proxy Router)
     * @param puller The contract address that executes the pull operation (e.g. Seaport Conduit)
     * @param tradeData The trade execution bytes on the marketplace
     */
    function sellNftToMarketPull(
        Lien calldata lien,
        uint256 lienId,
        uint256 amount,
        address marketplace,
        address puller,
        bytes calldata tradeData
    ) external payable;

    /**
     * @notice Push-based sell NFT to market (this contract initiates NFT transfer)
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     * @param amount Declared ETH amount for NFT sale
     * @param marketplace The contract address of the marketplace
     * @param tradeData The trade execution bytes to route to the marketplace
     */
    function sellNftToMarketPush(
        Lien calldata lien,
        uint256 lienId,
        uint256 amount,
        address marketplace,
        bytes calldata tradeData
    ) external payable;

    /**
     * @notice Buy NFT from market
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     * @param tokenId The ID of the NFT being bought
     * @param amount Declared ETH amount for NFT purchase
     * @param spender The spender address to approve WETH spending, zero address to use ETH
     * @param marketplace The address of the marketplace
     * @param tradeData The trade execution bytes on the marketplace
     */
    function buyNftFromMarket(
        Lien calldata lien,
        uint256 lienId,
        uint256 tokenId,
        uint256 amount,
        address spender,
        address marketplace,
        bytes calldata tradeData
    ) external;

    /**
     * @notice Swap NFT with ETH
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     */
    function swapWithEth(Lien calldata lien, uint256 lienId) external payable;

    /**
     * @notice Repay loan with NFT
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     * @param tokenId The ID of the NFT being used to repay the loan
     */
    function repayWithNft(Lien calldata lien, uint256 lienId, uint256 tokenId) external;

    /**
     * @notice Refinance an existing loan with a new one
     * @param oldLien Reconstructed old lien info
     * @param oldLienId The ID for the existing lien
     * @param newLien Reconstructed new lien info
     * @param newLienId The ID for the new lien
     */
    function refinanceLoan(
        Lien calldata oldLien,
        uint256 oldLienId,
        Lien calldata newLien,
        uint256 newLienId
    ) external payable;

    /*==============================================================
                                 Bid Logic
    ==============================================================*/

    /**
     * @notice Trader offers a bid for loan
     * @param collection The address to the NFT collection
     * @param margin Margin to use, should satisfy: margin <= msg.value + accountBalance[msg.sender]
     * @param price Bade desired price for NFT supplier
     * @param rate Bade interest rate for NFT supplier
     * @return lienId newly generated lienId
     */
    function offerBid(
        address collection,
        uint256 margin,
        uint256 price,
        uint256 rate
    ) external payable returns (uint256 lienId);

    /**
     * @notice Trader offers a bid for loan
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     * @param margin Margin to use, should satisfy: margin <= msg.value + accountBalance[msg.sender]
     * @param price Bade desired price for NFT supplier
     * @param rate Bade interest rate for NFT supplier
     */
    function updateBid(
        Lien calldata lien,
        uint256 lienId,
        uint256 margin,
        uint256 price,
        uint256 rate
    ) external payable;

    /**
     * @notice Trader cancels a opened bid (not yet accepted)
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     */
    function cancelBid(Lien calldata lien, uint256 lienId) external;

    /**
     * @notice Supplier accepts a bid by supplying an NFT and pull-based sell to market
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     * @param tokenId The ID of the NFT being supplied
     * @param amount Declared ETH amount for NFT sale
     * @param marketplace The address of the marketplace (e.g. Seaport Proxy Router)
     * @param puller The contract address that executes the pull operation (e.g. Seaport Conduit)
     * @param tradeData The trade execution bytes on the marketplace
     */
    function acceptBidSellNftToMarketPull(
        Lien calldata lien,
        uint256 lienId,
        uint256 tokenId,
        uint256 amount,
        address marketplace,
        address puller,
        bytes calldata tradeData
    ) external;

    /**
     * @notice Supplier accepts a bid by supplying an NFT and push-based sell to market
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     * @param tokenId The ID of the NFT being supplied
     * @param amount Declared ETH amount for NFT sale
     * @param marketplace The address of the marketplace
     * @param tradeData The trade execution bytes on the marketplace
     */
    function acceptBidSellNftToMarketPush(
        Lien calldata lien,
        uint256 lienId,
        uint256 tokenId,
        uint256 amount,
        address marketplace,
        bytes calldata tradeData
    ) external;

    /*==============================================================
                               Auction Logic
    ==============================================================*/

    /**
     * @notice Start auction for a loan
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     */
    function startLoanAuction(Lien calldata lien, uint256 lienId) external;

    /**
     * @notice Stop an auction for a loan
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     */
    function stopLoanAuction(Lien calldata lien, uint256 lienId) external;

    /**
     * @notice Buy NFT from auction
     * @param lien Reconstructed lien info
     * @param lienId The lien ID
     * @param tokenId The ID of the NFT being bought
     */
    function auctionSellNft(Lien calldata lien, uint256 lienId, uint256 tokenId) external;

    /*==============================================================
                               Admin Logic
    ==============================================================*/

    /**
     * @notice Register a trusted marketplace address
     * @param marketplace The address of the marketplace
     */
    function registerMarketplace(address marketplace) external;

    /**
     * @notice Unregister a marketplace address
     * @param marketplace The address of the marketplace
     */
    function unregisterMarketplace(address marketplace) external;

    /**
     * @notice Update treasury rate
     * @param rate The treasury rate in bips
     */
    function setTreasuryRate(uint256 rate) external;

    /**
     * @notice Withdraw treasury balance
     * @param receiver The address to receive the treasury balance
     */
    function withdrawTreasury(address receiver) external;
}