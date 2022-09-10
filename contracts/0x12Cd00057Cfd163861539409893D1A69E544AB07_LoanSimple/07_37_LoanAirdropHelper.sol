// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ILoanCommon.sol";
import "./LoanStructures.sol";
import "../../interfaces/ILoanManager.sol";
import "../../utils/KeysMapping.sol";
import "../../interfaces/IDispatcher.sol";
import "../../interfaces/IAllowedPartners.sol";
import "../../interfaces/IAllowedERC20s.sol";
import "../../interfaces/IAirdropBurstLoan.sol";
import "../../interfaces/INftWrapper.sol";
import "../../airdrop/IAirdropAcceptorFactory.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library LoanAirdropHelper {
    event AirdropPulledBurstloan(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 nftCollateralId,
        address nftCollateralContract,
        address target,
        bytes data
    );

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
        LoanStructures.LoanTerms memory _loan,
        address _target,
        bytes calldata _data,
        address _nftAirdrop,
        uint256 _nftAirdropId,
        bool _is1155,
        uint256 _nftAirdropAmount,
        IDispatcher _hub
    ) external {
        ILoanManager loanCoordinator = ILoanManager(
            _hub.getContract(ILoanCommon(address(this)).LOAN_COORDINATOR())
        );

        address borrower;

        // scoped to aviod stack too deep
        {
            ILoanManager.Loan memory loanCoordinatorData = loanCoordinator.getLoanData(_loanId);
            uint256 notesNftId = loanCoordinatorData.notesNftId;
            if (_loan.borrower != address(0)) {
                borrower = _loan.borrower;
            } else {
                borrower = IERC721(loanCoordinator.obligationReceiptToken()).ownerOf(notesNftId);
            }
        }

        require(msg.sender == borrower, "Only borrower can airdrop");

        {
            IAirdropBurstLoan airdropBurstLoan = IAirdropBurstLoan(_hub.getContract(KeysMapping.AIRDROP_FLASH_LOAN));

            _transferNFT(_loan, address(this), address(airdropBurstLoan));

            airdropBurstLoan.pullAirdrop(
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

        emit AirdropPulledBurstloan(
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
        LoanStructures.LoanTerms storage _loan,
        IDispatcher _hub
    ) external returns (address instance, uint256 receiverId) {
        ILoanManager loanCoordinator = ILoanManager(
            _hub.getContract(ILoanCommon(address(this)).LOAN_COORDINATOR())
        );
        // Fetch the current lender of the promissory note corresponding to this overdue loan.
        ILoanManager.Loan memory loanCoordinatorData = loanCoordinator.getLoanData(_loanId);
        uint256 notesNftId = loanCoordinatorData.notesNftId;

        address borrower;

        if (_loan.borrower != address(0)) {
            borrower = _loan.borrower;
        } else {
            borrower = IERC721(loanCoordinator.obligationReceiptToken()).ownerOf(notesNftId);
        }

        require(msg.sender == borrower, "Only borrower can wrapp");

        IAirdropAcceptorFactory factory = IAirdropAcceptorFactory(_hub.getContract(KeysMapping.AIRDROP_FACTORY));
        (instance, receiverId) = factory.createAirdropAcceptor(address(this));

        // transfer collateral to airdrop receiver wrapper
        _transferNFTtoAirdropAcceptor(_loan, instance, borrower);

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

    function _transferNFT(
        LoanStructures.LoanTerms memory _loan,
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

    function _transferNFTtoAirdropAcceptor(
        LoanStructures.LoanTerms memory _loan,
        address _airdropAcceptorInstance,
        address _airdropBeneficiary
    ) internal {
        Address.functionDelegateCall(
            _loan.nftCollateralWrapper,
            abi.encodeWithSelector(
                INftWrapper(_loan.nftCollateralWrapper).wrapAirdropAcceptor.selector,
                _airdropAcceptorInstance,
                _loan.nftCollateralContract,
                _loan.nftCollateralId,
                _airdropBeneficiary
            ),
            "NFT was not successfully migrated"
        );
    }
}