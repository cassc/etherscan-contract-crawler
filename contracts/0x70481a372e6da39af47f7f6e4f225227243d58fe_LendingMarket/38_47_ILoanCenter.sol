//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Trustus} from "../protocol/Trustus/Trustus.sol";

interface ILoanCenter {
    function createLoan(
        address owner,
        address lendingPool,
        uint256 amount,
        uint256 genesisNFTId,
        address nftAddress,
        uint256[] memory nftTokenIds,
        uint256 borrowRate
    ) external returns (uint256);

    function getLoan(
        uint256 loanId
    ) external view returns (DataTypes.LoanData memory);

    function getLoanState(
        uint256 loanId
    ) external view returns (DataTypes.LoanState);

    function getLoanLiquidationData(
        uint256 loanId
    ) external view returns (DataTypes.LoanLiquidationData memory);

    function getLoanAuctioneerFee(
        uint256 loanId
    ) external view returns (uint256);

    function repayLoan(uint256 loanId) external;

    function liquidateLoan(uint256 loanId) external;

    function auctionLoan(uint256 loanId, address user, uint256 bid) external;

    function updateLoanAuctionBid(
        uint256 loanId,
        address user,
        uint256 bid
    ) external;

    function getLoansCount() external view returns (uint256);

    function getNFTLoanId(
        address nftAddress,
        uint256 nftTokenID
    ) external view returns (uint256);

    function getLoanLendingPool(uint256 loanId) external view returns (address);

    function getLoanMaxDebt(
        uint256 loanId,
        uint256 tokensPrice
    ) external view returns (uint256);

    function getLoanDebt(uint256 loanId) external view returns (uint256);

    function getLoanInterest(uint256 loanId) external view returns (uint256);

    function getLoanTokenIds(
        uint256 loanId
    ) external view returns (uint256[] memory);

    function getLoanCollectionAddress(
        uint256 loanId
    ) external view returns (address);

    function updateLoanDebtTimestamp(
        uint256 loanId,
        uint256 newDebtTimestamp
    ) external;

    function updateLoanAmount(uint256 loanId, uint256 newAmount) external;

    function getCollectionLiquidationThreshold(
        address collection
    ) external view returns (uint256);

    function getCollectionMaxLTV(
        address collection
    ) external view returns (uint256);
}