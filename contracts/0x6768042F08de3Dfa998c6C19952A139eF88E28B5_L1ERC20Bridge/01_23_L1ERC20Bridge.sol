pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./interfaces/IL1Bridge.sol";
import "./interfaces/IL2Bridge.sol";

import "../common/interfaces/IAllowList.sol";
import "../common/AllowListed.sol";
import "../common/interfaces/IERC20.sol";
import "../common/libraries/UnsafeBytes.sol";
import "../common/ReentrancyGuard.sol";
import "../common/L2ContractHelper.sol";

/// @author Matter Labs
contract L1ERC20Bridge is IL1Bridge, AllowListed, ReentrancyGuard {
    /// @dev The smart contract that manages the list with permission to call contract functions
    IAllowList immutable allowList;

    /// @dev zkSync smart contract that used to operate with L2 via asynchronous L2 <-> L1 communication
    IMailbox immutable zkSyncMailbox;

    // TODO: evaluate constant
    uint256 constant DEPOSIT_ERGS_LIMIT = 2097152;

    // TODO: evaluate constant
    uint256 constant DEPLOY_L2_BRIDGE_COUNTERPART_ERGS_LIMIT = 2097152;

    /// @dev mapping L2 block number => message number => flag
    /// @dev Used to indicate that zkSync L2 -> L1 message was already processed
    mapping(uint256 => mapping(uint256 => bool)) public isWithdrawalFinalized;

    /// @dev mapping account => L1 token address => L2 deposit transaction hash => amount
    /// @dev Used for saving amount of deposited fund, to claim them in case the deposit transaction will fail
    mapping(address => mapping(address => mapping(bytes32 => uint256))) depositAmount;

    /// @dev address of deployed L2 bridge counterpart
    address public l2Bridge;

    /// @dev address of factory that deploys proxy for L2 tokens.
    address public l2TokenFactory;

    /// @dev bytecode hash of L2 token contract
    bytes32 public l2ProxyTokenBytecodeHash;

    /// @dev Contract is expected to be used as proxy implementation.
    /// @dev Initialize the implementation to prevent Parity hack.
    constructor(IMailbox _mailbox, IAllowList _allowList) reentrancyGuardInitializer {
        zkSyncMailbox = _mailbox;
        allowList = _allowList;
    }

    /// @dev Initializes a contract bridge for later use. Expected to be used in the proxy.
    /// @dev During initialization deploys L2 bridge counterpart as well as provides some factory deps for it.
    /// @param _factoryDeps A list of raw bytecodes that needed for deployment of L2 bridge.
    /// @notice _factoryDeps[0] == a raw bytecode of L2 bridge.
    /// @notice _factoryDeps[1] == a raw bytecode of token proxy.
    /// @param _l2TokenFactory Pre-calculated address of L2 token beacon proxy.
    /// @notice At the time of the function call, it is not yet deployed in L2, but knowledge of its address.
    /// @notice is necessary for determining L2 token address by L1 address, see `l2TokenAddress(address)` function.
    /// @param _governor Address which can change l2 token implementation.
    function initialize(
        bytes[] memory _factoryDeps,
        address _l2TokenFactory,
        address _governor
    ) external reentrancyGuardInitializer {
        require(_factoryDeps.length == 2);
        l2ProxyTokenBytecodeHash = L2ContractHelper.hashL2Bytecode(_factoryDeps[1]);
        l2TokenFactory = _l2TokenFactory;

        bytes32 create2Salt = bytes32(0);
        bytes memory create2Input = abi.encode(address(this), l2ProxyTokenBytecodeHash, _governor);
        bytes32 l2BridgeBytecodeHash = L2ContractHelper.hashL2Bytecode(_factoryDeps[0]);
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

        zkSyncMailbox.requestL2Transaction(
            DEPLOYER_SYSTEM_CONTRACT_ADDRESS,
            0,
            deployL2BridgeCalldata,
            DEPLOY_L2_BRIDGE_COUNTERPART_ERGS_LIMIT,
            _factoryDeps
        );
    }

    function deposit(
        address _l2Receiver,
        address _l1Token,
        uint256 _amount
    ) external payable nonReentrant senderCanCallFunction(allowList) returns (bytes32 txHash) {
        uint256 amount = _depositFunds(msg.sender, IERC20(_l1Token), _amount);
        require(amount > 0, "1T"); // empty deposit amount

        bytes memory l2TxCalldata = _getDepositL2Calldata(msg.sender, _l2Receiver, _l1Token, amount);
        txHash = zkSyncMailbox.requestL2Transaction{value: msg.value}(
            l2Bridge,
            0,
            l2TxCalldata,
            DEPOSIT_ERGS_LIMIT,
            new bytes[](0)
        );

        depositAmount[msg.sender][_l1Token][txHash] = amount;

        emit DepositInitiated(msg.sender, _l2Receiver, _l1Token, _amount);
    }

    function _depositFunds(
        address _from,
        IERC20 _token,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 balanceBefore = _token.balanceOf(address(this));
        _token.transferFrom(_from, address(this), _amount);
        uint256 balanceAfter = _token.balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }

    function _getDepositL2Calldata(
        address _l1Sender,
        address _l2Receiver,
        address _l1Token,
        uint256 _amount
    ) internal view returns (bytes memory txCalldata) {
        // TODO: shouldn't be requested for every deposit
        bytes memory gettersData = _getERC20Getters(_l1Token);

        txCalldata = abi.encodeWithSelector(
            IL2Bridge.finalizeDeposit.selector,
            _l1Sender,
            _l2Receiver,
            _l1Token,
            _amount,
            gettersData
        );
    }

    /// @dev receives and parses (name, symbol, decimals) from token contract
    function _getERC20Getters(address _token) internal view returns (bytes memory data) {
        (, bytes memory data1) = _token.staticcall(abi.encodeWithSelector(IERC20.name.selector));
        (, bytes memory data2) = _token.staticcall(abi.encodeWithSelector(IERC20.symbol.selector));
        (, bytes memory data3) = _token.staticcall(abi.encodeWithSelector(IERC20.decimals.selector));
        data = abi.encode(data1, data2, data3);
    }

    /// @dev withdraw funds for a failed deposit
    function claimFailedDeposit(
        address _depositSender,
        address _l1Token,
        bytes32 _l2TxHash,
        uint256 _l2BlockNumber,
        uint256 _l2MessageIndex,
        uint16 _l2TxNumberInBlock,
        bytes32[] calldata _merkleProof
    ) external nonReentrant senderCanCallFunction(allowList) {
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

        uint256 amount = depositAmount[_depositSender][_l1Token][_l2TxHash];
        require(amount > 0);

        depositAmount[_depositSender][_l1Token][_l2TxHash] = 0;
        _withdrawFunds(_depositSender, IERC20(_l1Token), amount);

        emit ClaimedFailedDeposit(_depositSender, _l1Token, amount);
    }

    function finalizeWithdrawal(
        uint256 _l2BlockNumber,
        uint256 _l2MessageIndex,
        uint16 _l2TxNumberInBlock,
        bytes calldata _message,
        bytes32[] calldata _merkleProof
    ) external nonReentrant senderCanCallFunction(allowList) {
        require(!isWithdrawalFinalized[_l2BlockNumber][_l2MessageIndex], "pw");

        L2Message memory l2ToL1Message = L2Message({
            txNumberInBlock: _l2TxNumberInBlock,
            sender: l2Bridge,
            data: _message
        });

        (address l1Receiver, address l1Token, uint256 amount) = _parseL2WithdrawalMessage(l2ToL1Message.data);
        // Preventing the stack too deep error
        {
            bool success = zkSyncMailbox.proveL2MessageInclusion(
                _l2BlockNumber,
                _l2MessageIndex,
                l2ToL1Message,
                _merkleProof
            );
            require(success, "nq");
        }

        isWithdrawalFinalized[_l2BlockNumber][_l2MessageIndex] = true;
        _withdrawFunds(l1Receiver, IERC20(l1Token), amount);

        emit WithdrawalFinalized(l1Receiver, l1Token, amount);
    }

    function _parseL2WithdrawalMessage(bytes memory _l2ToL1message)
        internal
        pure
        returns (
            address l1Receiver,
            address l1Token,
            uint256 amount
        )
    {
        // Check that message length is correct.
        // It should be equal to the length of the function signature + address + address + uint256 = 4 + 20 + 20 + 32 = 76 (bytes).
        require(_l2ToL1message.length == 76, "kk");

        (uint32 functionSignature, uint256 offset) = UnsafeBytes.readUint32(_l2ToL1message, 0);
        require(bytes4(functionSignature) == this.finalizeWithdrawal.selector, "nt");

        (l1Receiver, offset) = UnsafeBytes.readAddress(_l2ToL1message, offset);
        (l1Token, offset) = UnsafeBytes.readAddress(_l2ToL1message, offset);
        (amount, offset) = UnsafeBytes.readUint256(_l2ToL1message, offset);
    }

    function _withdrawFunds(
        address _to,
        IERC20 _token,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 balanceBefore = _token.balanceOf(address(this));
        _token.transfer(_to, _amount);
        uint256 balanceAfter = _token.balanceOf(address(this));

        return balanceBefore - balanceAfter;
    }

    function l2TokenAddress(address _l1Token) public view returns (address) {
        bytes32 constructorInputHash = keccak256(abi.encode(address(l2TokenFactory), ""));
        bytes32 salt = bytes32(uint256(uint160(_l1Token)));

        return L2ContractHelper.computeCreate2Address(l2Bridge, salt, l2ProxyTokenBytecodeHash, constructorInputHash);
    }
}