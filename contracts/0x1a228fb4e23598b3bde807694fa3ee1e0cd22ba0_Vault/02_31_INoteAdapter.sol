// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Interface to a note adapter, a generic interface to a lending
 * platform
 */
interface INoteAdapter {
    /**************/
    /* Structures */
    /**************/

    /// @notice Asset information
    /// @param token Token contract
    /// @param tokenId Token ID
    struct AssetInfo {
        address token;
        uint256 tokenId;
    }

    /// @notice Loan information
    /// @param loanId Loan ID
    /// @param borrower Borrower
    /// @param principal Principal value
    /// @param repayment Repayment value
    /// @param maturity Maturity in seconds since Unix epoch
    /// @param duration Duration in seconds
    /// @param currencyToken Currency token used by loan
    /// @param collateralToken Collateral token contract
    /// @param collateralTokenId Collateral token ID
    struct LoanInfo {
        uint256 loanId;
        address borrower;
        uint256 principal;
        uint256 repayment;
        uint64 maturity;
        uint64 duration;
        address currencyToken;
        address collateralToken;
        uint256 collateralTokenId;
    }

    /***************/
    /* Primary API */
    /***************/

    /// @notice Get note adapter name
    /// @return Note adapter name
    function name() external view returns (string memory);

    /// @notice Get note token of lending platform
    /// @return Note token contract
    function noteToken() external view returns (IERC721);

    /// @notice Check if loan is supported by Vault
    /// @param noteTokenId Note token ID
    /// @param currencyToken Currency token used by Vault
    /// @return True if supported, otherwise false
    function isSupported(
        uint256 noteTokenId,
        address currencyToken
    ) external view returns (bool);

    /// @notice Get loan information
    /// @param noteTokenId Note token ID
    /// @return Loan information
    function getLoanInfo(
        uint256 noteTokenId
    ) external view returns (LoanInfo memory);

    /// @notice Get loan collateral assets
    /// @param noteTokenId Note token ID
    /// @return Loan collateral assets
    function getLoanAssets(
        uint256 noteTokenId
    ) external view returns (AssetInfo[] memory);

    /// @notice Get target and calldata to liquidate loan
    /// @param loanId Loan ID
    /// @return Target address
    /// @return Encoded calldata with selector
    function getLiquidateCalldata(
        uint256 loanId
    ) external view returns (address, bytes memory);

    /// @notice Get target and calldata to unwrap collateral
    /// @param loanId Loan ID
    /// @return Target address
    /// @return Encoded calldata with selector
    function getUnwrapCalldata(
        uint256 loanId
    ) external view returns (address, bytes memory);

    /// @notice Check if loan is repaid
    /// @param loanId Loan ID
    /// @return True if repaid, otherwise false
    function isRepaid(uint256 loanId) external view returns (bool);

    /// @notice Check if loan is liquidated
    /// @param loanId Loan ID
    /// @return True if liquidated, otherwise false
    function isLiquidated(uint256 loanId) external view returns (bool);

    /// @notice Check if loan is expired
    /// @param loanId Loan ID
    /// @return True if expired, otherwise false
    function isExpired(uint256 loanId) external view returns (bool);
}