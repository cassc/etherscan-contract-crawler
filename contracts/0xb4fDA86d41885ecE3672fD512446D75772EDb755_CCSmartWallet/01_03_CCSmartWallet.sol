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

    event DirectUSDCTransfer(address userAddress, uint256 amount, address smartWallet);

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
     * @dev update current signer
     *
     * @param newAddress address of new signer
     */
    function updateSigner(address newAddress) public onlyAdmin {
        address oldSigner = currentSigner;
        currentSigner = newAddress;
        emit SignerUpdated(oldSigner, newAddress);
    }

    /**
     * @dev update current admin
     *
     * @param newAddress address of new admin
     */
    function updateAdmin(address newAddress) public onlyAdmin {
        address oldAdmin = admin;
        admin = newAddress;
        emit AdminUpdated(oldAdmin, newAddress);
    }

    /**
     * @dev update current market maker
     *
     * @param newAddress address of new market maker
     */
    function updateMarketMaker(address newAddress) public onlyAdmin {
        address oldMarketMaker = defaultMarketMaker;
        defaultMarketMaker = newAddress;
        emit MarketMakerUpdated(oldMarketMaker, defaultMarketMaker);
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

    /**
     * @notice method for sending response tx to user. It handles erc20 and direct usdc transfer
     *
     * @param signature signature from validator that allows to execute tx
     * @param _callData encoded calldata of the swap
     * @param srcTxHash tx hash in source network from user where he sent usdc to our pool
     * @param srcChainId source network id
     * @param _value value of swap
     * @param destToken in case of erc20 swap this must be zero address. In case direct usdc transfer it must be usdc address in current network
     * @param amount usdc amount in case of direct transfer. Should be 0 in case of swap
     * @param userAddress address of token receiver
     */
    function executeResponseTx(
        bytes calldata signature,
        bytes calldata _callData,
        bytes32 srcTxHash,
        uint256 srcChainId,
        uint256 _value,
        address destToken,
        uint256 amount,
        address userAddress
    ) external returns (bool status) {
        require(
            !alreadyExecutedFirstTransactions[string(abi.encodePacked(srcChainId, srcTxHash))],
            "First tx was alredy handled"
        );

        bool isUsdc = destToken != address(0);
        bool txSuccess;
        bytes32 messageHash;

        if (isUsdc) {
            messageHash = _getTxMessageHash(srcTxHash, destToken, _value, _callData);
        } else {
            messageHash = _getTxMessageHash(srcTxHash, defaultMarketMaker, _value, _callData);
        }
        address recoveredMsgSigner = messageHash.recover(signature);
        require(recoveredMsgSigner == currentSigner, "Signature is created incorrectly or not created by signer");

        if (isUsdc) {
            (txSuccess, ) = destToken.call{value: _value}(_callData);
        } else {
            (txSuccess, ) = defaultMarketMaker.call{value: _value}(_callData);
        }
        require(txSuccess, "tx failed");

        alreadyExecutedFirstTransactions[string(abi.encodePacked(srcChainId, srcTxHash))] = true;

        if (isUsdc) {
            emit DirectUSDCTransfer(userAddress, amount, address(this));
        }

        emit ResponseTxWasSent(srcChainId, srcTxHash);
        return txSuccess;
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