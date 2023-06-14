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
import {SIGNER_ROLE} from "xy3/Roles.sol";
import "./Errors.sol";

/**
 * @title  XY3
 * @author XY3
 * @notice Main contract for XY3 lending.
 */
contract LoanFacet is XY3Events, Pausable, ReentrancyGuard, AccessProxy {
    IAddressProvider immutable ADDRESS_PROVIDER;

    /**
     * @dev Init contract
     *
     * @param _addressProvider - AddressProvider contract
     */
    constructor(address _addressProvider) AccessProxy(_addressProvider) {
        ADDRESS_PROVIDER = IAddressProvider(_addressProvider);
    }

    function _burnNotes(uint _xy3NftId) internal {
        IXy3Nft borrowerNote;
        IXy3Nft lenderNote;
        (borrowerNote, lenderNote) = _getNotes();
        borrowerNote.burn(_xy3NftId);
        lenderNote.burn(_xy3NftId);
    }

    function _getNotes()
        private
        view
        returns (IXy3Nft borrowerNote, IXy3Nft lenderNote)
    {
        borrowerNote = IXy3Nft(ADDRESS_PROVIDER.getBorrowerNote());
        lenderNote = IXy3Nft(ADDRESS_PROVIDER.getLenderNote());
    }

    /**
     * @dev Restricted function, only called by self from borrow/batch with target.
     * @param _sender  The borrow's msg.sender.
     * @param _param  The borrow CallData's data, encode loadId only.
     */
    function repay(address _sender, bytes calldata _param) external {
        if (msg.sender != address(this)) {
            revert InvalidCaller();
        }
        uint32 loanId = abi.decode(_param, (uint32));
        _repay(_sender, loanId);
    }

    
    function repay(uint32 _loanId) public nonReentrant {
        _repay(msg.sender, _loanId);
    }

    function liquidate(uint32 _loanId) external nonReentrant {

        LoanInfo memory info 
            = IXY3(address(this)).getLoanInfo(_loanId);

        if (block.timestamp <= info.maturityDate) {
            revert LoanNotOverdue(_loanId);
        }

        (
            address borrower,
            address lender
        ) = _getParties(_loanId);


        if (msg.sender != lender) {
            revert OnlyLenderCanLiquidate(_loanId);
        }
        // Emit an event with all relevant details from this transaction.
        emit LoanLiquidated(
            _loanId,
            borrower,
            lender,
            info.borrowAmount,
            info.nftId,
            info.maturityDate,
            block.timestamp,
            info.nftAsset
        );

        // nft to lender
        IERC721(info.nftAsset).safeTransferFrom(address(this), lender, info.nftId);
        _resolveLoan(_loanId);
    }

    function _resolveLoan(uint32 _loanId) private {
        Storage.Loan storage main = Storage.getLoan();
        LoanDetail storage loan = main.loanDetails[_loanId];
        _burnNotes(_loanId);
        emit UpdateStatus(_loanId, StatusType.RESOLVED);
        //loan.state = StatusType.RESOLVED;
        assembly {
            sstore(loan.slot, 2)
        }
    }

    function _getParties(
        uint32 _loanId
    )
        internal
        view
        returns (address borrower, address lender)
    {
        borrower = IERC721(ADDRESS_PROVIDER.getBorrowerNote()).ownerOf(
            _loanId
        );
        lender = IERC721(ADDRESS_PROVIDER.getLenderNote()).ownerOf(_loanId);
    }

    function _repay(address payer, uint32 _loanId) internal {
        Storage.Config storage config = Storage.getConfig();

        LoanInfo memory info
            = IXY3(address(this)).getLoanInfo(_loanId);

        if (block.timestamp > info.maturityDate) {
            revert LoanIsExpired(_loanId);
        }

        (
            address borrower,
            address lender
        ) = _getParties(_loanId);

        IERC721(info.nftAsset).safeTransferFrom(address(this), borrower, info.nftId);

        // pay from the payer

        _repayAsset(
            payer,
            info.borrowAsset,
            lender,
            info.payoffAmount,
            config.adminFeeReceiver,
            info.adminFee
        );

        emit LoanRepaid(
            _loanId,
            borrower,
            lender,
            info.borrowAmount,
            info.nftId,
            info.payoffAmount,
            info.adminFee,
            info.nftAsset,
            info.borrowAsset
        );
        _resolveLoan(_loanId);
    }

    function _repayAsset(
        address payer,
        address borrowAsset,
        address lender,
        uint payoffAmount,
        address adminFeeReceiver,
        uint adminFee
    ) internal {
        // Paid back to lender
        _transferWithCompensation(
            payer,
            lender,
            borrowAsset,
            payoffAmount
        );
        // pay admin fee
        if (adminFee != 0 && adminFeeReceiver != address(0)) {
            _transferWithCompensation(
                payer,
                adminFeeReceiver,
                borrowAsset,
                adminFee
            );
        }
    }

    function _transferWithCompensation(address compensator, address receiver, address asset, uint256 targetAmount) internal {
        if(targetAmount == 0) {
            return;
        }
        uint256 ownedAmount = IERC20(asset).balanceOf(address(this));
        if(ownedAmount == 0) {
            IDelegateV3(ADDRESS_PROVIDER.getTransferDelegate()).erc20Transfer(
                compensator,
                receiver,
                asset,
                targetAmount
            );
        } else {
            if(ownedAmount < targetAmount) {
                if(compensator != receiver) {
                    IDelegateV3(ADDRESS_PROVIDER.getTransferDelegate()).erc20Transfer(
                        compensator,
                        address(this),
                        asset,
                        targetAmount - ownedAmount
                    );
                } else { // _compensator is same as _receiver, just transfer owned amount to _receiver
                    targetAmount = ownedAmount;
                }
            }
            IERC20(asset).transfer(
                receiver,
                targetAmount
            );
        }
    }
    
    function cancelOffer(Offer calldata _offer) public {
        Storage.Loan storage s = Storage.getLoan();
        Signature memory signature = _offer.signature;
        if (msg.sender != signature.signer) {
            revert OnlySignerCanCancelOffer();
        }
        bytes32 offerHash = verifyOfferSignature(
            _offer,
            s.userCounters[msg.sender]
        );
        s.offerStatus[offerHash].cancelled = true;
        emit OfferCancelled(msg.sender, offerHash, s.userCounters[msg.sender]);
    }

    function increaseCounter() public {
        Storage.Loan storage s = Storage.getLoan();
        uint256 counter = s.userCounters[msg.sender];
        s.userCounters[msg.sender] += 1;
        emit OfferCancelled(msg.sender, bytes32(0), counter);
    }

    
    function verifyOfferSignature(
        Offer calldata _offer,
        uint256 _counter
    ) internal view returns (bytes32 offerHash) {
        Signature calldata _signature = _offer.signature;
        bytes memory data = getSignData(
            _offer,
            _offer.signature.signer,
            _counter
        );
        offerHash = ECDSA.toEthSignedMessageHash(keccak256(data));
        if (
            !SignatureChecker.isValidSignatureNow(
                _signature.signer,
                offerHash,
                _signature.signature
            )
        ) {
            revert InvalidSignature();
        }
    }

    function getSignData(
        Offer calldata _offer,
        address signer,
        uint _counter
    ) internal view returns (bytes memory data) {
        data = abi.encodePacked(
            _offer.itemType,
            _offer.borrowAsset,
            _offer.borrowAmount,
            _offer.repayAmount,
            _offer.nftAsset,
            _offer.tokenId,
            _offer.borrowDuration,
            _offer.validUntil,
            _offer.amount,
            address(this),
            block.chainid,
            signer,
            _counter
        );
    }
}