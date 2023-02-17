// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MultiSignCoinTx {
    event CoinTxSubmit(uint256 indexed txId);
    event CoinTxApprove(address indexed signer, uint256 indexed txId);
    event CoinTxRevoke(address indexed signer, uint256 indexed txId);
    event CoinTxExecute(uint256 indexed txId);

    struct CoinTransaction {
        uint256 value;
        uint256 delayTime;
        bool executed;
    }

    CoinTransaction[] public coinTransactions;
    address[] public coinTxSigners;
    uint256 public coinTxRequired;
    mapping(address => bool) public isCoinTxSigner;
    mapping(uint256 => mapping(address => bool)) public coinTxApproved;

    modifier onlyCoinTxSigner() {
        require(isCoinTxSigner[msg.sender], "MultiSignCoinTx: not tx signer");
        _;
    }

    modifier coinTxExists(uint256 _txId) {
        require(
            _txId < coinTransactions.length,
            "MultiSignCoinTx: tx does not exist"
        );
        _;
    }

    modifier coinTxNotApproved(uint256 _txId) {
        require(
            !coinTxApproved[_txId][msg.sender],
            "MultiSignCoinTx: tx already approved"
        );
        _;
    }

    modifier coinTxNotExecuted(uint256 _txId) {
        require(
            !coinTransactions[_txId].executed,
            "MultiSignCoinTx: tx already executed"
        );
        _;
    }

    modifier coinTxUnlocked(uint256 _txId) {
        require(
            block.timestamp >= coinTransactions[_txId].delayTime,
            "MultiSignCoinTx: tokens have not been unlocked"
        );
        _;
    }

    constructor(address[] memory _signers, uint256 _required) {
        require(_signers.length > 0, "MultiSignCoinTx: tx signers required");
        require(
            _required > 0 && _required <= _signers.length,
            "MultiSignCoinTx: invalid required number of tx signers"
        );

        for (uint256 i; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0), "MultiSignCoinTx: invalid tx signer");
            require(
                !isCoinTxSigner[signer],
                "MultiSignCoinTx: tx signer is not unique"
            );

            isCoinTxSigner[signer] = true;
            coinTxSigners.push(signer);
        }

        coinTxRequired = _required;
    }

    function getCoinTransactions()
        external
        view
        returns (CoinTransaction[] memory)
    {
        return coinTransactions;
    }

    function coinTxSubmit(uint256 _value, uint256 _delayTime)
        external
        onlyCoinTxSigner
    {
        coinTransactions.push(
            CoinTransaction({
                value: _value,
                delayTime: block.timestamp + 172800 + _delayTime,
                executed: false
            })
        );
        emit CoinTxSubmit(coinTransactions.length - 1);
    }

    function coinTxApprove(uint256 _txId)
        external
        onlyCoinTxSigner
        coinTxExists(_txId)
        coinTxNotApproved(_txId)
        coinTxNotExecuted(_txId)
    {
        coinTxApproved[_txId][msg.sender] = true;
        emit CoinTxApprove(msg.sender, _txId);
    }

    function getCoinTxApprovalCount(uint256 _txId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i; i < coinTxSigners.length; i++) {
            if (coinTxApproved[_txId][coinTxSigners[i]]) {
                count += 1;
            }
        }
    }

    function coinTxRevoke(uint256 _txId)
        external
        onlyCoinTxSigner
        coinTxExists(_txId)
        coinTxNotExecuted(_txId)
    {
        require(
            coinTxApproved[_txId][msg.sender],
            "MultiSignCoinTx: tx not approved"
        );

        coinTxApproved[_txId][msg.sender] = false;
        emit CoinTxRevoke(msg.sender, _txId);
    }

    function coinTxExecute(uint256 _txId)
        public
        virtual
        onlyCoinTxSigner
        coinTxExists(_txId)
        coinTxNotExecuted(_txId)
        coinTxUnlocked(_txId)
    {
        require(
            getCoinTxApprovalCount(_txId) >= coinTxRequired,
            "MultiSignCoinTx: the required number of approvals is insufficient"
        );

        CoinTransaction storage coinTransaction = coinTransactions[_txId];
        coinTransaction.executed = true;
        emit CoinTxExecute(_txId);
    }
}