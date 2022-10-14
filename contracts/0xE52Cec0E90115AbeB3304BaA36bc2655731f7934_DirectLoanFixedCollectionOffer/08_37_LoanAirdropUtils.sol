// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./IDirectLoanBase.sol";
import "./LoanData.sol";
import "../../../interfaces/IDirectLoanCoordinator.sol";
import "../../../utils/ContractKeys.sol";
import "../../../interfaces/INftfiHub.sol";
import "../../../interfaces/IPermittedPartners.sol";
import "../../../interfaces/IPermittedERC20s.sol";
import "../../../interfaces/IAirdropFlashLoan.sol";
import "../../../interfaces/INftWrapper.sol";
import "../../../airdrop/IAirdropReceiverFactory.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title  LoanAirdropUtils
 * @author NFTfi
 * @notice Helper library for LoanBase
 */
library LoanAirdropUtils {
    /**
     * @notice This event is fired whenever a flashloan is initiated to pull an airdrop
     *
     * @param  loanId - A unique identifier for this particular loan, sourced from the Loan Coordinator.
     * @param  borrower - The address of the borrower.
     * @param  nftCollateralId - The ID within the AirdropReceiver for the NFT being used as collateral for this
     * loan.
     * @param  nftCollateralContract - The ERC721 contract of the NFT collateral
     * @param target - address of the airdropping contract
     * @param data - function selector to be called
     */
    event AirdropPulledFlashloan(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 nftCollateralId,
        address nftCollateralContract,
        address target,
        bytes data
    );

    /**
     * @notice This event is fired whenever the collateral gets wrapped in an airdrop receiver
     *
     * @param  loanId - A unique identifier for this particular loan, sourced from the Loan Coordinator.
     * @param  borrower - The address of the borrower.
     * @param  nftCollateralId - The ID within the AirdropReceiver for the NFT being used as collateral for this
     * loan.
     * @param  nftCollateralContract - The contract of the NFT collateral
     * @param receiverId - id of the created AirdropReceiver, takes the place of nftCollateralId on the loan
     * @param receiverInstance - address of the created AirdropReceiver
     */
    event CollateralWrapped(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 nftCollateralId,
        address nftCollateralContract,
        uint256 receiverId,
        address receiverInstance
    );

    function pullAirdrop(
        uint32 _loanId,
        LoanData.LoanTerms memory _loan,
        address _target,
        bytes calldata _data,
        address _nftAirdrop,
        uint256 _nftAirdropId,
        bool _is1155,
        uint256 _nftAirdropAmount,
        INftfiHub _hub
    ) external {
        IDirectLoanCoordinator loanCoordinator = IDirectLoanCoordinator(
            _hub.getContract(IDirectLoanBase(address(this)).LOAN_COORDINATOR())
        );

        address borrower;

        // scoped to aviod stack too deep
        {
            IDirectLoanCoordinator.Loan memory loanCoordinatorData = loanCoordinator.getLoanData(_loanId);
            uint256 smartNftId = loanCoordinatorData.smartNftId;
            if (_loan.borrower != address(0)) {
                borrower = _loan.borrower;
            } else {
                borrower = IERC721(loanCoordinator.obligationReceiptToken()).ownerOf(smartNftId);
            }
        }

        require(msg.sender == borrower, "Only borrower can airdrop");

        {
            IAirdropFlashLoan airdropFlashLoan = IAirdropFlashLoan(_hub.getContract(ContractKeys.AIRDROP_FLASH_LOAN));

            _transferNFT(_loan, address(this), address(airdropFlashLoan));

            airdropFlashLoan.pullAirdrop(
                _loan.nftCollateralContract,
                _loan.nftCollateralId,
                _loan.nftCollateralWrapper,
                _target,
                _data,
                _nftAirdrop,
                _nftAirdropId,
                _is1155,
                _nftAirdropAmount,
                borrower
            );
        }

        // revert if the collateral hasn't been transferred back before it ends
        require(
            INftWrapper(_loan.nftCollateralWrapper).isOwner(
                address(this),
                _loan.nftCollateralContract,
                _loan.nftCollateralId
            ),
            "Collateral should be returned"
        );

        emit AirdropPulledFlashloan(
            _loanId,
            borrower,
            _loan.nftCollateralId,
            _loan.nftCollateralContract,
            _target,
            _data
        );
    }

    function wrapCollateral(
        uint32 _loanId,
        LoanData.LoanTerms storage _loan,
        INftfiHub _hub
    ) external returns (address instance, uint256 receiverId) {
        IDirectLoanCoordinator loanCoordinator = IDirectLoanCoordinator(
            _hub.getContract(IDirectLoanBase(address(this)).LOAN_COORDINATOR())
        );
        // Fetch the current lender of the promissory note corresponding to this overdue loan.
        IDirectLoanCoordinator.Loan memory loanCoordinatorData = loanCoordinator.getLoanData(_loanId);
        uint256 smartNftId = loanCoordinatorData.smartNftId;

        address borrower;

        if (_loan.borrower != address(0)) {
            borrower = _loan.borrower;
        } else {
            borrower = IERC721(loanCoordinator.obligationReceiptToken()).ownerOf(smartNftId);
        }

        require(msg.sender == borrower, "Only borrower can wrapp");

        IAirdropReceiverFactory factory = IAirdropReceiverFactory(_hub.getContract(ContractKeys.AIRDROP_FACTORY));
        (instance, receiverId) = factory.createAirdropReceiver(address(this));

        // transfer collateral to airdrop receiver wrapper
        _transferNFTtoAirdropReceiver(_loan, instance, borrower);

        emit CollateralWrapped(
            _loanId,
            borrower,
            _loan.nftCollateralId,
            _loan.nftCollateralContract,
            receiverId,
            instance
        );

        // set the receiver as the new collateral
        _loan.nftCollateralContract = instance;
        _loan.nftCollateralId = receiverId;
    }

    /**
     * @dev Transfers several types of NFTs using a wrapper that knows how to handle each case.
     *
     * @param _loan -
     * @param _sender - Current owner of the NFT
     * @param _recipient - Recipient of the transfer
     */
    function _transferNFT(
        LoanData.LoanTerms memory _loan,
        address _sender,
        address _recipient
    ) internal {
        Address.functionDelegateCall(
            _loan.nftCollateralWrapper,
            abi.encodeWithSelector(
                INftWrapper(_loan.nftCollateralWrapper).transferNFT.selector,
                _sender,
                _recipient,
                _loan.nftCollateralContract,
                _loan.nftCollateralId
            ),
            "NFT not successfully transferred"
        );
    }

    /**
     * @dev Transfers several types of NFTs to an airdrop receiver with an airdrop beneficiary
     * address attached as supplementing data using a wrapper that knows how to handle each case.
     *
     * @param _loan -
     * @param _airdropReceiverInstance - Recipient of the transfer
     * @param _airdropBeneficiary - Beneficiary of the future airdops
     */
    function _transferNFTtoAirdropReceiver(
        LoanData.LoanTerms memory _loan,
        address _airdropReceiverInstance,
        address _airdropBeneficiary
    ) internal {
        Address.functionDelegateCall(
            _loan.nftCollateralWrapper,
            abi.encodeWithSelector(
                INftWrapper(_loan.nftCollateralWrapper).wrapAirdropReceiver.selector,
                _airdropReceiverInstance,
                _loan.nftCollateralContract,
                _loan.nftCollateralId,
                _airdropBeneficiary
            ),
            "NFT was not successfully migrated"
        );
    }
}