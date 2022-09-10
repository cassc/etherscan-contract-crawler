// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../../notesNft/NotesNft.sol";
import "../../interfaces/ILoanManager.sol";
import "../../interfaces/IDispatcher.sol";
import "../../utils/Ownable.sol";
import "../../utils/KeysMapping.sol";

contract LoanManager is ILoanManager, Ownable {
    IDispatcher public immutable hub;

    mapping(bytes32 => address) private typeContracts;

    mapping(address => bytes32) private contractTypes;

    uint32 public totalNumLoans = 0;

    // The address that deployed this contract
    address private immutable _deployer;
    bool private _initialized = false;

    mapping(uint32 => Loan) private loans;

    address public override promissoryNoteToken;
    address public override obligationReceiptToken;

    event UpdateStatus(
        uint32 indexed loanId,
        uint64 indexed notesNftId,
        address indexed loanContract,
        StatusType newStatus
    );

    event TypeUpdated(bytes32 indexed loanType, address indexed loanContract);

    modifier onlyInitialized() {
        require(_initialized, "not initialized");

        _;
    }

    constructor(
        address _dispatcher,
        address _admin,
        string[] memory _loanTypes,
        address[] memory _loanContracts
    ) Ownable(_admin) {
        hub = IDispatcher(_dispatcher);
        _deployer = msg.sender;
        _registerLoanTypes(_loanTypes, _loanContracts);
    }

    function initialize(address _promissoryNoteToken, address _obligationReceiptToken) external {
        require(msg.sender == _deployer, "only deployer");
        require(!_initialized, "already initialized");
        require(_promissoryNoteToken != address(0), "promissoryNoteToken is zero");
        require(_obligationReceiptToken != address(0), "obligationReceiptToken is zero");

        _initialized = true;
        promissoryNoteToken = _promissoryNoteToken;
        obligationReceiptToken = _obligationReceiptToken;
    }

    function registerLoan(address _lender, bytes32 _loanType) external override onlyInitialized returns (uint32) {
        address loanContract = msg.sender;

        require(getContractFromType(_loanType) == loanContract, "Caller must be registered for loan type");

        // (loanIds start at 1)
        totalNumLoans += 1;

        uint64 notesNftId = uint64(uint256(keccak256(abi.encodePacked(address(this), totalNumLoans))));

        Loan memory newLoan = Loan({status: StatusType.NEW, loanContract: loanContract, notesNftId: notesNftId});

        // Issue an ERC721 promissory note to the lender that gives them the
        // right to either the principal-plus-interest or the collateral.
        NotesNft(promissoryNoteToken).mint(_lender, notesNftId, abi.encode(totalNumLoans));

        loans[totalNumLoans] = newLoan;

        emit UpdateStatus(totalNumLoans, notesNftId, loanContract, StatusType.NEW);

        return totalNumLoans;
    }

    function mintObligationReceipt(uint32 _loanId, address _borrower) external override onlyInitialized {
        address loanContract = msg.sender;

        require(getTypeFromContract(loanContract) != bytes32(0), "Caller must a be registered loan type");

        uint64 notesNftId = loans[_loanId].notesNftId;
        // nedded?
        require(notesNftId != 0, "loan doesn't exist");
        // nedded?
        require(NotesNft(promissoryNoteToken).exists(notesNftId), "Promissory note should exist");
        // nedded?
        require(!NotesNft(obligationReceiptToken).exists(notesNftId), "Obligation r shouldn't exist");

        // Issue an ERC721 obligation receipt to the borrower that gives them the
        // right to pay back the loan and get the collateral back.
        NotesNft(obligationReceiptToken).mint(_borrower, notesNftId, abi.encode(_loanId));
    }

    function resolveLoan(uint32 _loanId) external override onlyInitialized {
        Loan storage loan = loans[_loanId];
        require(loan.status == StatusType.NEW, "Loan status must be New");
        require(loan.loanContract == msg.sender, "Not the same Contract that registered Loan");

        loan.status = StatusType.RESOLVED;

        NotesNft(promissoryNoteToken).burn(loan.notesNftId);
        if (NotesNft(obligationReceiptToken).exists(loan.notesNftId)) {
            NotesNft(obligationReceiptToken).burn(loan.notesNftId);
        }

        emit UpdateStatus(_loanId, loan.notesNftId, msg.sender, StatusType.RESOLVED);
    }

    function getLoanData(uint32 _loanId) external view override returns (Loan memory) {
        return loans[_loanId];
    }

    function isValidLoanId(uint32 _loanId, address _loanContract) external view override returns (bool validity) {
        validity = loans[_loanId].loanContract == _loanContract;
    }

    function registerLoanType(string memory _loanType, address _loanContract) external onlyOwner {
        _registerLoanType(_loanType, _loanContract);
    }

    function registerLoanTypes(string[] memory _loanTypes, address[] memory _loanContracts) external onlyOwner {
        _registerLoanTypes(_loanTypes, _loanContracts);
    }

    function getContractFromType(bytes32 _loanType) public view returns (address) {
        return typeContracts[_loanType];
    }

    function getTypeFromContract(address _loanContract) public view returns (bytes32) {
        return contractTypes[_loanContract];
    }

    function _registerLoanType(string memory _loanType, address _loanContract) internal {
        require(bytes(_loanType).length != 0, "loanType is empty");
        bytes32 loanTypeKey = KeysMapping.keyToId(_loanType);

        typeContracts[loanTypeKey] = _loanContract;
        contractTypes[_loanContract] = loanTypeKey;

        emit TypeUpdated(loanTypeKey, _loanContract);
    }

    function _registerLoanTypes(string[] memory _loanTypes, address[] memory _loanContracts) internal {
        require(_loanTypes.length == _loanContracts.length, "function information arity mismatch");

        for (uint256 i = 0; i < _loanTypes.length; i++) {
            _registerLoanType(_loanTypes[i], _loanContracts[i]);
        }
    }
}