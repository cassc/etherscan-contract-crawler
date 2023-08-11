// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/INFTLending.sol";
import "./interfaces/zharta/ILoansPeripheral.sol";
import "./interfaces/zharta/ILoansCore.sol";
import {IWETH} from "../IWETH.sol";

/// @title Zharta Lending
/// @notice Manages creating and repaying a loan on Zharta
contract ZhartaLending is INFTLending {
    using SafeERC20 for IERC20;

    /// @notice LoansPeripheral Contract
    ILoansPeripheral public constant loansPeripheral =
        ILoansPeripheral(0xaF2F471d3B46171f876f465165dcDF2F0E788636);

    /// @notice LoansCore Contract
    ILoansCore public constant loansCore =
        ILoansCore(0x5Be916Cff5f07870e9Aef205960e07d9e287eF27);

    /// @notice Collateral Vault Core
    address public constant collateralVaultCore = 0x7CA34cF45a119bEBEf4D106318402964a331DfeD;

    /// @notice Invalid Collateral Length
    error InvalidCollateralLength();

    /// @inheritdoc INFTLending
    function getLoanDetails(
        uint256 _loanId
    ) external view returns (LoanDetails memory loanDetails) {
        // Get Loan for loanId
        ILoansCore.Loan memory loanDetail = loansCore.getLoan(
            address(this),
            _loanId
        );

        uint256 repayAmount = loansPeripheral.getLoanPayableAmount(
            address(this),
            _loanId,
            block.timestamp
        );

        return LoanDetails(
            loanDetail.amount, // borrowAmount
            repayAmount, // repayAmount
            loanDetail.maturity, // loanExpiration
            loanDetail.collaterals[0].contractAddress, // nftAddress
            loanDetail.collaterals[0].tokenId // tokenId
        );
    }

    /// @inheritdoc INFTLending
    function borrow(
        bytes calldata _inputData
    ) external payable returns (uint256) {
        // Decode `inputData` into required parameters
        ILoansPeripheral.Calldata memory callData = abi.decode(
            _inputData,
            (ILoansPeripheral.Calldata)
        );

        if (callData.collaterals.length != 1) revert InvalidCollateralLength();

        IERC721 nft = IERC721(callData.collaterals[0].contractAddress);

        // Approve
        if (!nft.isApprovedForAll(address(this), collateralVaultCore)) {
            nft.setApprovalForAll(collateralVaultCore, true);
        }

        // Borrow on Zharta
        uint256 loanId = loansPeripheral.reserveEth(
            callData.amount,
            callData.interest,
            callData.maturity,
            callData.collaterals,
            callData.delegations,
            callData.deadline,
            callData.nonce,
            callData.genesisToken,
            callData.v,
            callData.r,
            callData.s
        );

        // Return loan id
        return loanId;
    }

    /// @inheritdoc INFTLending
    function repay(uint256 _loanId, address _receiver) external payable {
        // Get Loan for loanId
        ILoansCore.Loan memory loanDetail = loansCore.getLoan(
            address(this),
            _loanId
        );

        // Pay back loan
        loansPeripheral.pay{value: msg.value}(_loanId);

        if (_receiver != address(this)) {
            // Transfer collateral NFT to the user
            IERC721(loanDetail.collaterals[0].contractAddress).safeTransferFrom(
                address(this),
                _receiver,
                loanDetail.collaterals[0].tokenId
            );
        }
    }

    receive() external payable {}
}