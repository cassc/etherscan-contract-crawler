// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CCSmartWallet {
    using ECDSA for bytes32;

    event Deposit(address indexed sender, uint256 amount);

    event SignerUpdated(address indexed oldSigner, address indexed newSigner);

    event AdminUpdated(address oldAdmin, address newAdmin);

    event MarketMakerUpdated(address oldMarketMaker, address newMarketMaker);

    event ArbitraryTxWasSent(address to, bytes callData);

    event ResponseTxWasSent(uint256 srcChainId, bytes32 srcTransactionHash);

    mapping(string => bool) internal alreadyExecutedFirstTransactions;

    address public currentSigner;

    address public admin;

    address public defaultMarketMaker = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller is not an admin");
        _;
    }

    constructor(address newSigner, address newAdmin) {
        currentSigner = newSigner;
        admin = newAdmin;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev update signer, admin or marketMaker address. Only admin can call this method.
     *
     * @param updateMode update mode. Can be or 'signer', 'admin' or 'marketMaker'
     * @param newAddress address of new signer or admin
     */
    function updateArbitraryAddresses(string calldata updateMode, address newAddress) public onlyAdmin {
        require(
            keccak256(bytes(updateMode)) == keccak256(bytes("signer")) ||
                keccak256(bytes(updateMode)) == keccak256(bytes("admin")) ||
                keccak256(bytes(updateMode)) == keccak256(bytes("marketMaker")),
            "Update mode is not correct"
        );
        if (keccak256(bytes(updateMode)) == keccak256(bytes("signer"))) {
            address oldSigner = currentSigner;
            currentSigner = newAddress;
            emit SignerUpdated(oldSigner, newAddress);
        }
        if (keccak256(bytes(updateMode)) == keccak256(bytes("admin"))) {
            address oldAdmin = admin;
            admin = newAddress;
            emit AdminUpdated(oldAdmin, newAddress);
        }
        if (keccak256(bytes(updateMode)) == keccak256(bytes("marketMaker"))) {
            address oldMarketMaker = defaultMarketMaker;
            defaultMarketMaker = newAddress;
            emit MarketMakerUpdated(oldMarketMaker, defaultMarketMaker);
        }
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _callData
    ) external onlyAdmin returns (bool txStatus, bytes memory data) {
        (bool success, bytes memory txData) = _to.call{value: _value}(_callData);
        require(success, "arbitrary tx failed");
        emit ArbitraryTxWasSent(_to, _callData);
        return (success, txData);
    }

    function executeResponseTx(
        bytes32 srcTxHash,
        uint256 srcChainId,
        uint256 _value,
        bytes calldata _callData,
        bytes calldata signature
    ) external returns (bool txStatus, bytes memory data) {
        require(
            !alreadyExecutedFirstTransactions[string(abi.encodePacked(srcChainId, srcTxHash))],
            "First tx was alredy handled"
        );
        bytes32 messageHash = _getTxMessageHash(srcTxHash, defaultMarketMaker, _value, _callData);
        address recoveredMsgSigner = messageHash.recover(signature);
        require(recoveredMsgSigner == currentSigner, "Signature is created incorrectly or not created by signer");
        (bool success, bytes memory txData) = defaultMarketMaker.call{value: _value}(_callData);
        require(success, "tx failed");
        alreadyExecutedFirstTransactions[string(abi.encodePacked(srcChainId, srcTxHash))] = true;
        emit ResponseTxWasSent(srcChainId, srcTxHash);
        return (success, txData);
    }

    function _getTxMessageHash(
        bytes32 srcTxHash,
        address _to,
        uint256 _value,
        bytes calldata _callData
    ) private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.chainid, srcTxHash, _to, _value, _callData));
    }
}