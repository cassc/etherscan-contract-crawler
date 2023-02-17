// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MultiSignReceiverChangeTx {
    event RcTxSubmit(uint256 indexed txId);
    event RcTxApprove(address indexed signer, uint256 indexed txId);
    event RcTxRevoke(address indexed signer, uint256 indexed txId);
    event RcTxExecute(uint256 indexed txId);

    struct RcTransaction {
        address receiver;
        bool executed;
    }

    RcTransaction[] public rcTransactions;
    address[] public rcTxSigners;
    uint256 public rcTxRequired;
    mapping(address => bool) public isRcTxSigner;
    mapping(uint256 => mapping(address => bool)) public rcTxApproved;

    modifier onlyRcTxSigner() {
        require(
            isRcTxSigner[msg.sender],
            "MultiSignReceiverChangeTx: not tx signer"
        );
        _;
    }

    modifier rcTxExists(uint256 _txId) {
        require(
            _txId < rcTransactions.length,
            "MultiSignReceiverChangeTx: tx does not exist"
        );
        _;
    }

    modifier rcTxNotApproved(uint256 _txId) {
        require(
            !rcTxApproved[_txId][msg.sender],
            "MultiSignReceiverChangeTx: tx already approved"
        );
        _;
    }

    modifier rcTxNotExecuted(uint256 _txId) {
        require(
            !rcTransactions[_txId].executed,
            "MultiSignReceiverChangeTx: tx already executed"
        );
        _;
    }

    constructor(address[] memory _signers, uint256 _required) {
        require(
            _signers.length > 0,
            "MultiSignReceiverChangeTx: tx signers required"
        );
        require(
            _required > 0 && _required <= _signers.length,
            "MultiSignReceiverChangeTx: invalid required number of tx signers"
        );

        for (uint256 i; i < _signers.length; i++) {
            address signer = _signers[i];
            require(
                signer != address(0),
                "MultiSignReceiverChangeTx: invalid tx signer"
            );
            require(
                !isRcTxSigner[signer],
                "MultiSignReceiverChangeTx: tx signer is not unique"
            );

            isRcTxSigner[signer] = true;
            rcTxSigners.push(signer);
        }

        rcTxRequired = _required;
    }

    function getRcTransactions()
        external
        view
        returns (RcTransaction[] memory)
    {
        return rcTransactions;
    }

    function rcTxSubmit(address _receiver) external onlyRcTxSigner {
        rcTransactions.push(
            RcTransaction({receiver: _receiver, executed: false})
        );
        emit RcTxSubmit(rcTransactions.length - 1);
    }

    function rcTxApprove(uint256 _txId)
        external
        onlyRcTxSigner
        rcTxExists(_txId)
        rcTxNotApproved(_txId)
        rcTxNotExecuted(_txId)
    {
        rcTxApproved[_txId][msg.sender] = true;
        emit RcTxApprove(msg.sender, _txId);
    }

    function getRcTxApprovalCount(uint256 _txId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i; i < rcTxSigners.length; i++) {
            if (rcTxApproved[_txId][rcTxSigners[i]]) {
                count += 1;
            }
        }
    }

    function rcTxRevoke(uint256 _txId)
        external
        onlyRcTxSigner
        rcTxExists(_txId)
        rcTxNotExecuted(_txId)
    {
        require(
            rcTxApproved[_txId][msg.sender],
            "MultiSignReceiverChangeTx: tx not approved"
        );

        rcTxApproved[_txId][msg.sender] = false;
        emit RcTxRevoke(msg.sender, _txId);
    }

    function rcTxExecute(uint256 _txId)
        public
        virtual
        onlyRcTxSigner
        rcTxExists(_txId)
        rcTxNotExecuted(_txId)
    {
        require(
            getRcTxApprovalCount(_txId) >= rcTxRequired,
            "MultiSignReceiverChangeTx: the required number of approvals is insufficient"
        );

        RcTransaction storage rcTransaction = rcTransactions[_txId];
        rcTransaction.executed = true;
        emit RcTxExecute(_txId);
    }
}