// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "xy3/interfaces/IXY3.sol";
import "xy3/interfaces/IDelegateV3.sol";
import "xy3/interfaces/IAddressProvider.sol";
import "xy3/interfaces/IServiceFee.sol";
import "xy3/interfaces/IXy3Nft.sol";
import "xy3/DataTypes.sol";
import "xy3/utils/Pausable.sol";
import "xy3/utils/ReentrancyGuard.sol";
import "xy3/utils/Storage.sol";
import "xy3/utils/AccessProxy.sol";
import "xy3/interfaces/IAddressProvider.sol";
import {SIGNER_ROLE} from "xy3/Roles.sol";
import "./Errors.sol";
import "forge-std/console.sol";

contract LensFacet {
    IAddressProvider immutable ADDRESS_PROVIDER;

    constructor(address _addressProvider) {
        ADDRESS_PROVIDER = IAddressProvider(_addressProvider);
    }

    function getLoanInfo(
        uint32 _loanId
    ) public view returns (LoanInfo memory loanInfo) {
        Storage.Config storage config = Storage.getConfig();

        Storage.Loan storage s = Storage.getLoan();
        LoanDetail memory _loan = s.loanDetails[_loanId];

        if (StatusType.NEW != _loan.state) {
            revert LoanNotActive(_loanId);
        }

        loanInfo.nftAsset = config.nftAssetList[_loan.nftAssetIndex];

        loanInfo.borrowAsset = config.borrowAssetList[_loan.borrowAssetIndex];

        loanInfo.nftId = _loan.nftTokenId;

        uint256 totalInterest = _loan.repayAmount - _loan.borrowAmount;
        uint repayDuration = block.timestamp - _loan.loanStart;
        if (repayDuration < config.minBorrowDuration) {
            repayDuration = config.minBorrowDuration;
        }
        uint dueInterest = (totalInterest * repayDuration) / _loan.loanDuration;
        uint undueInterest = 0;
        if (totalInterest > dueInterest) {
            undueInterest =
                ((totalInterest - dueInterest) *
                    config.undueInterestRepayRatio) /
                HUNDRED_PERCENT;
        }
        loanInfo.adminFee =
            ((dueInterest + undueInterest) * _loan.adminShare) /
            HUNDRED_PERCENT;

        loanInfo.payoffAmount =
            _loan.borrowAmount +
            dueInterest +
            undueInterest -
            loanInfo.adminFee;

        loanInfo.maturityDate =
            uint256(_loan.loanStart) +
            uint256(_loan.loanDuration);
        loanInfo.borrowAmount = _loan.borrowAmount;
    }

    function getRepayAmount(
        uint32 _loanId
    ) external view  returns (uint256) {
        Storage.Loan storage s = Storage.getLoan();

        LoanDetail storage loan = s.loanDetails[_loanId];
        return loan.repayAmount;
    }

    function getUserCounter(address user) public view returns (uint) {
        Storage.Loan storage s = Storage.getLoan();
        return s.userCounters[user];
    }
    
    function loanState(uint32 _loanId) external view returns (StatusType) {
        Storage.Loan storage s = Storage.getLoan();
        return s.loanDetails[_loanId].state;
    }
    
    function loanDetails(
        uint32 _loanId
    ) external view returns (LoanDetail memory) {
        Storage.Loan storage s = Storage.getLoan();
        return s.loanDetails[_loanId];
    }

    function getMinimalRefinanceAmounts(uint32 _loanId)
        external
        view
        returns (uint256 payoffAmount, uint256 adminFee, uint256 minServiceFee, uint16 feeRate)
    {
        LoanInfo memory info = getLoanInfo(_loanId);
        feeRate = IServiceFee(address(this)).getServiceFeeRate(address(this), info.nftAsset);
        minServiceFee = (info.payoffAmount + info.adminFee) * feeRate / (HUNDRED_PERCENT - feeRate);
        adminFee = info.adminFee;
        payoffAmount = info.payoffAmount;
    }

    function getRefinanceCompensatedAmount(uint32 _loanId, uint256 newBorrowAmount)
        external
        view
        returns (uint256 compensatedAmount)
    {
        LoanInfo memory info = getLoanInfo(_loanId);
        (, uint256 serviceFee) = IServiceFee(address(this)).getServiceFee(address(this), info.nftAsset, newBorrowAmount);
        if(newBorrowAmount >= info.payoffAmount + info.adminFee + serviceFee) {
            return 0;
        }
        return info.payoffAmount + info.adminFee + serviceFee - newBorrowAmount;
    }
}