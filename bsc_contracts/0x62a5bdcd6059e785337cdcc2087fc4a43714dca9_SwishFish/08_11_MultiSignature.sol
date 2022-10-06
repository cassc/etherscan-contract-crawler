// SPDX-License-Identifier: MIT
// Coin2Fish Contract (utils/MultiSigWallet.sol)

pragma solidity 0.8.17;

contract MultiSignature {
    event DepositProposal(address indexed sender, uint amount);
    event SubmitProposal(uint indexed proposalId);
    event ApproveProposal(address indexed owner, uint indexed proposalId);
    event RevokeProposal(address indexed owner, uint indexed proposalId);

    struct Proposal {
        address author;
        bool executed;
        bool updateSalesStatus;
        bool salesEnabled;
        bool swapAndAddLiquidity;
        bool updateWithdrawOptions;
        uint256 withdrawPrice;
        bool updateTaxesFees;
        uint256 heisenVerseTaxFee;
        uint256 marketingTaxFee;
        uint256 teamTaxFee;
        uint256 liquidityTaxFee;
        bool transferBackend;
        address backendAddress;
    }

    Proposal[] public proposals;

    mapping(uint => mapping(address => bool)) internal proposalApproved;
    constructor() {}

    modifier proposalExists(uint _proposalId) {
        require(_proposalId < proposals.length, "MultiSignatureWallet: proposal does not exist");
        _;
    }

    modifier proposalNotApproved(uint _proposalId) {
        require(!proposalApproved[_proposalId][msg.sender], "MultiSignatureWallet: proposal already was approved by owner");
        _;
    }

    modifier proposalNotExecuted(uint _proposalId) {
        require(!proposals[_proposalId].executed, "MultiSignatureWallet: proposal was already executed");
        _;
    }
}