// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../libraries/types/DataTypes.sol';

/**
 * @title IOpenSkyLoan
 * @author OpenSky Labs
 * @notice Defines the basic interface for OpenSkyLoan.  This loan NFT is composable and can be used in other DeFi protocols 
 **/
interface IOpenSkyLoan is IERC721 {

    /**
     * @dev Emitted on mint()
     * @param tokenId The ID of the loan
     * @param recipient The address that will receive the loan NFT
     **/
    event Mint(uint256 indexed tokenId, address indexed recipient);

    /**
     * @dev Emitted on end()
     * @param tokenId The ID of the loan
     * @param onBehalfOf The address the repayer is repaying for
     * @param repayer The address of the user initiating the repayment()
     **/
    event End(uint256 indexed tokenId, address indexed onBehalfOf, address indexed repayer);

    /**
     * @dev Emitted on startLiquidation()
     * @param tokenId The ID of the loan
     * @param liquidator The address of the liquidator
     **/
    event StartLiquidation(uint256 indexed tokenId, address indexed liquidator);

    /**
     * @dev Emitted on endLiquidation()
     * @param tokenId The ID of the loan
     * @param liquidator The address of the liquidator
     **/
    event EndLiquidation(uint256 indexed tokenId, address indexed liquidator);

    /**
     * @dev Emitted on updateStatus()
     * @param tokenId The ID of the loan
     * @param status The status of loan
     **/
    event UpdateStatus(uint256 indexed tokenId, DataTypes.LoanStatus indexed status);

    /**
     * @dev Emitted on flashClaim()
     * @param receiver The address of the flash loan receiver contract
     * @param sender The address that will receive tokens
     * @param nftAddress The address of the collateralized NFT
     * @param tokenId The ID of collateralized NFT
     **/
    event FlashClaim(address indexed receiver, address sender, address indexed nftAddress, uint256 indexed tokenId);

    /**
     * @dev Emitted on claimERC20Airdrop()
     * @param token The address of the ERC20 token
     * @param to The address that will receive the ERC20 tokens
     * @param amount The amount of the tokens
     **/
    event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);

    /**
     * @dev Emitted on claimERC721Airdrop()
     * @param token The address of ERC721 token
     * @param to The address that will receive the eRC721 tokens
     * @param ids The ID of the token
     **/
    event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);

    /**
     * @dev Emitted on claimERC1155Airdrop()
     * @param token The address of the ERC1155 token
     * @param to The address that will receive the ERC1155 tokens
     * @param ids The ID of the token
     * @param amounts The amount of the tokens
     * @param data packed params to pass to the receiver as extra information
     **/
    event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

    /**
     * @notice Mints a loan NFT to user
     * @param reserveId The ID of the reserve
     * @param borrower The address of the borrower
     * @param nftAddress The contract address of the collateralized NFT 
     * @param nftTokenId The ID of the collateralized NFT
     * @param amount The amount of the loan
     * @param duration The duration of the loan
     * @param borrowRate The borrow rate of the loan
     * @return loanId and loan data
     **/
    function mint(
        uint256 reserveId,
        address borrower,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount,
        uint256 duration,
        uint256 borrowRate
    ) external returns (uint256 loanId, DataTypes.LoanData memory loan);

    /**
     * @notice Starts liquidation of the loan in default
     * @param tokenId The ID of the defaulted loan
     **/
    function startLiquidation(uint256 tokenId) external;

    /**
     * @notice Ends liquidation of a loan that is fully settled
     * @param tokenId The ID of the loan
     **/
    function endLiquidation(uint256 tokenId) external;

    /**
     * @notice Terminates the loan
     * @param tokenId The ID of the loan
     * @param onBehalfOf The address the repayer is repaying for
     * @param repayer The address of the repayer
     **/
    function end(uint256 tokenId, address onBehalfOf, address repayer) external;
    
    /**
     * @notice Returns the loan data
     * @param tokenId The ID of the loan
     * @return The details of the loan
     **/
    function getLoanData(uint256 tokenId) external view returns (DataTypes.LoanData calldata);

    /**
     * @notice Returns the status of a loan
     * @param tokenId The ID of the loan
     * @return The status of the loan
     **/
    function getStatus(uint256 tokenId) external view returns (DataTypes.LoanStatus);

    /**
     * @notice Returns the borrow interest of the loan
     * @param tokenId The ID of the loan
     * @return The borrow interest of the loan
     **/
    function getBorrowInterest(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the borrow balance of a loan, including borrow interest
     * @param tokenId The ID of the loan
     * @return The borrow balance of the loan
     **/
    function getBorrowBalance(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the penalty fee of the loan
     * @param tokenId The ID of the loan
     * @return The penalty fee of the loan
     **/
    function getPenalty(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the ID of the loan
     * @param nftAddress The address of the collateralized NFT
     * @param tokenId The ID of the collateralized NFT
     * @return The ID of the loan
     **/
    function getLoanId(address nftAddress, uint256 tokenId) external view returns (uint256);

    /**
     * @notice Allows smart contracts to access the collateralized NFT within one transaction,
     * as long as the amount taken plus a fee is returned
     * @dev IMPORTANT There are security concerns for developers of flash loan receiver contracts that must be carefully considered
     * @param receiverAddress The address of the contract receiving the funds, implementing IOpenSkyFlashClaimReceiver interface
     * @param loanIds The ID of loan being flash-borrowed
     * @param params packed params to pass to the receiver as extra information
     **/
    function flashClaim(
        address receiverAddress,
        uint256[] calldata loanIds,
        bytes calldata params
    ) external;

    /**
     * @notice Claim the ERC20 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive ERC20 token
     * @param amount The amount of the ERC20 token
     **/
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Claim the ERC721 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC721 token
     * @param ids The ID of the ERC721 token
     **/
    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external;

    /**
     * @notice Claim the ERC1155 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC1155 tokens
     * @param ids The ID of the ERC1155 token
     * @param amounts The amount of the ERC1155 tokens
     * @param data packed params to pass to the receiver as extra information
     **/
    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}