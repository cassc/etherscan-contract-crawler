// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;
import "../DataTypes.sol";

library Storage {
    struct OfferState {
        bool cancelled;
        uint16 amount;
    }

    bytes32 internal constant CONFIG_STORAGE = keccak256("config.storage");
    bytes32 internal constant LOAN_STORAGE = keccak256("loan.storage");
    bytes32 internal constant SERVICE_FEE_STORAGE = keccak256("serviceFee.storage");

    struct Config {
        /**
         * @dev Admin fee receiver, can be updated by admin.
         */
        address adminFeeReceiver;
        /**
         * @dev Borrow durations, can be updated by admin.
         */
        uint256 maxBorrowDuration;
        uint256 minBorrowDuration;
        /**
         * @dev The fee percentage is taken by the contract admin's as a
         * fee, which is from the the percentage of lender earned.
         * Unit is hundreths of percent, like adminShare/10000.
         */
        uint16 adminShare;
        /**
         * @dev Undue interest should be payed partially.
         * For example, if a borrower repayed a 7 days loan in 5 days,
         * and the total interest for 7 days is _total_, then the borrower
         * should pay 
         * _total_ * 5 / 7 + _total_ * 2 / 7 * undueInterestRepayRatio/10000
         */
        uint16 undueInterestRepayRatio;
        /**
         * @dev The permitted ERC20 currency for this contract.
         */
        mapping(address => bool) erc20Permits;
        /**
         * @dev The permitted ERC721 token or collections for this contract.
         */
        mapping(address => bool) erc721Permits;
        /**
         * @dev The permitted agent for this contract, index is target + selector;
         */
        mapping(address => mapping(bytes4 => bool)) agentPermits;

        mapping(address => uint8) borrowAssets;
        mapping(address => uint32) nftAssets;
        address[] borrowAssetList;
        address[] nftAssetList;

    }

    struct Loan {
        mapping(uint32 => LoanDetail) loanDetails;
        /**
         * @notice A mapping that takes a user's address and a cancel timestamp.
         *
         */

        mapping(bytes32 => OfferState) offerStatus;
        mapping(address => uint256) userCounters;
        uint32 totalNumLoans;
    }

    struct ServiceFee {
        mapping(bytes32 => uint16) adminFees;
        mapping(bytes32 => bool) feeFlags;
    }

    function getConfig() internal pure returns (Config storage s) {
        bytes32 position = CONFIG_STORAGE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := position
        }
    }

    function getLoan() internal pure returns (Loan storage s) {
        bytes32 position = LOAN_STORAGE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := position
        }
    }

    function getServiceFee() internal pure returns (ServiceFee storage s) {
        bytes32 position = SERVICE_FEE_STORAGE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := position
        }
    }
}