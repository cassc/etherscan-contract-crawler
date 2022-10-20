pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./interfaces/IL1Bridge.sol";
import "./interfaces/IL2Bridge.sol";

import "../common/interfaces/IAllowList.sol";
import "../common/AllowListed.sol";
import "../common/libraries/UnsafeBytes.sol";
import "../common/L2ContractHelper.sol";
import "../common/ReentrancyGuard.sol";

/// @author Matter Labs
contract L1EthBridge is IL1Bridge, AllowListed, ReentrancyGuard {
    /// @dev The smart contract that manages the list with permission to call contract functions
    IAllowList immutable allowList;

    /// @dev zkSync smart contract used to interact with L2 via asynchronous L2 <-> L1 communication
    IMailbox immutable zkSyncMailbox;

    // TODO: evaluate constant
    uint256 constant DEPOSIT_ERGS_LIMIT = 2097152;
    // TODO: evaluate constant
    uint256 constant DEPLOY_L2_BRIDGE_COUNTERPART_ERGS_LIMIT = 2097152;

    /// @dev Ether native coin has no real address on L1, so a conventional zero address is used.
    address constant CONVENTIONAL_ETH_ADDRESS = address(0);

    mapping(uint256 => mapping(uint256 => bool)) public isWithdrawalFinalized;

    mapping(address => mapping(bytes32 => uint256)) depositAmount;

    /// @dev address of deployed L2 bridge counterpart
    address public l2Bridge;

    /// @dev Contract is expected to be used as proxy implementation.
    /// @dev Initialize the implementation to prevent Parity hack.
    constructor(IMailbox _mailbox, IAllowList _allowList) reentrancyGuardInitializer {
        zkSyncMailbox = _mailbox;
        allowList = _allowList;
    }

    /// @dev Initializes a contract bridge for later use. Expected to be used in the proxy.
    /// @dev Deploys L2 bridge counterpart during initialization.
    /// @param _l2BridgeBytecode a raw bytecode of the L2 bridge contract, that will be deployed on L2.
    function initialize(bytes calldata _l2BridgeBytecode) external reentrancyGuardInitializer {
        bytes32 create2Salt = bytes32(0);
        bytes memory create2Input = abi.encode(address(this));
        bytes32 l2BridgeBytecodeHash = L2ContractHelper.hashL2Bytecode(_l2BridgeBytecode);
        bytes memory deployL2BridgeCalldata = abi.encodeWithSelector(
            IContractDeployer.create2.selector,
            create2Salt,
            l2BridgeBytecodeHash,
            create2Input
        );

        l2Bridge = L2ContractHelper.computeCreate2Address(
            address(this),
            create2Salt,
            l2BridgeBytecodeHash,
            keccak256(create2Input)
        );
        bytes[] memory factoryDeps = new bytes[](1);
        factoryDeps[0] = _l2BridgeBytecode;
        zkSyncMailbox.requestL2Transaction(
            DEPLOYER_SYSTEM_CONTRACT_ADDRESS,
            0,
            deployL2BridgeCalldata,
            DEPLOY_L2_BRIDGE_COUNTERPART_ERGS_LIMIT,
            factoryDeps
        );
    }

    function deposit(
        address _l2Receiver,
        address _l1Token,
        uint256 _amount
    ) external payable nonReentrant senderCanCallFunction(allowList) returns (bytes32 txHash) {
        require(_l1Token == CONVENTIONAL_ETH_ADDRESS);

        // Will revert if msg.value is less than the amount of the deposit
        uint256 zkSyncFee = msg.value - _amount;
        bytes memory l2TxCalldata = _getDepositL2Calldata(msg.sender, _l2Receiver, _amount);
        txHash = zkSyncMailbox.requestL2Transaction{value: zkSyncFee}(
            l2Bridge,
            0,
            l2TxCalldata,
            DEPOSIT_ERGS_LIMIT,
            new bytes[](0)
        );

        // Save deposit amount, to claim funds back if the L2 transaction will failed
        depositAmount[msg.sender][txHash] = _amount;

        emit DepositInitiated(msg.sender, _l2Receiver, _l1Token, _amount);
    }

    /// @dev serialize the transaction calldata for the L2 bridge counterpart
    function _getDepositL2Calldata(
        address _l1Sender,
        address _l2Receiver,
        uint256 _amount
    ) internal pure returns (bytes memory txCalldata) {
        txCalldata = abi.encodeWithSelector(
            IL2Bridge.finalizeDeposit.selector,
            _l1Sender,
            _l2Receiver,
            CONVENTIONAL_ETH_ADDRESS,
            _amount,
            hex""
        );
    }

    function claimFailedDeposit(
        address _depositSender,
        address _l1Token,
        bytes32 _l2TxHash,
        uint256 _l2BlockNumber,
        uint256 _l2MessageIndex,
        uint16 _l2TxNumberInBlock,
        bytes32[] calldata _merkleProof
    ) external override nonReentrant senderCanCallFunction(allowList) {
        require(_l1Token == CONVENTIONAL_ETH_ADDRESS);

        // Checks
        uint256 amount = depositAmount[_depositSender][_l2TxHash];
        require(amount != 0);

        L2Log memory l2Log = L2Log({
            l2ShardId: 0,
            isService: true,
            txNumberInBlock: _l2TxNumberInBlock,
            sender: BOOTLOADER_ADDRESS,
            key: _l2TxHash,
            value: bytes32(0)
        });
        bool success = zkSyncMailbox.proveL2LogInclusion(_l2BlockNumber, _l2MessageIndex, l2Log, _merkleProof);
        require(success);

        // Effects
        depositAmount[_depositSender][_l2TxHash] = 0;
        // Interactions
        _withdrawFunds(_depositSender, amount);

        emit ClaimedFailedDeposit(_depositSender, _l1Token, amount);
    }

    function finalizeWithdrawal(
        uint256 _l2BlockNumber,
        uint256 _l2MessageIndex,
        uint16 _l2TxNumberInBlock,
        bytes calldata _message,
        bytes32[] calldata _merkleProof
    ) external override nonReentrant senderCanCallFunction(allowList) {
        require(!isWithdrawalFinalized[_l2BlockNumber][_l2MessageIndex]);

        L2Message memory l2ToL1Message = L2Message({
            txNumberInBlock: _l2TxNumberInBlock,
            sender: l2Bridge,
            data: _message
        });

        (address l1Receiver, uint256 amount) = _parseL2WithdrawalMessage(_message);

        bool success = zkSyncMailbox.proveL2MessageInclusion(
            _l2BlockNumber,
            _l2MessageIndex,
            l2ToL1Message,
            _merkleProof
        );
        require(success);

        isWithdrawalFinalized[_l2BlockNumber][_l2MessageIndex] = true;
        _withdrawFunds(l1Receiver, amount);

        emit WithdrawalFinalized(l1Receiver, CONVENTIONAL_ETH_ADDRESS, amount);
    }

    function _parseL2WithdrawalMessage(bytes memory _message)
        internal
        pure
        returns (address l1Receiver, uint256 amount)
    {
        // Check that the message length is correct.
        // It should be equal to the length of the function signature + address + uint256 = 4 + 20 + 32 = 56 (bytes).
        require(_message.length == 56);

        (uint32 functionSignature, uint256 offset) = UnsafeBytes.readUint32(_message, 0);
        require(bytes4(functionSignature) == this.finalizeWithdrawal.selector);

        (l1Receiver, offset) = UnsafeBytes.readAddress(_message, offset);
        (amount, offset) = UnsafeBytes.readUint256(_message, offset);
    }

    function _withdrawFunds(address _to, uint256 _amount) internal {
        bool callSuccess;
        // Low-level assembly call, to avoid any memory copying (save gas)
        assembly {
            callSuccess := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        require(callSuccess);
    }

    /// @dev Always return zero address
    function l2TokenAddress(address) public pure returns (address) {
        return CONVENTIONAL_ETH_ADDRESS;
    }
}