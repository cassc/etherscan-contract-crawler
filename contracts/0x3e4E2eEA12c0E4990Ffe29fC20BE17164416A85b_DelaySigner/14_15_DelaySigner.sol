// SPDX-License-Identifier: LGPL-3.0-only
// @author st4rgard3n, Collab.Land, Raid Guild
pragma solidity >=0.8.0;

import "@gnosis.pm/zodiac/contracts/core/Modifier.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/ISafeSigner.sol";

contract DelaySigner is Modifier {

    using ECDSA for bytes32;

    event DelaySetup(
        address indexed initiator,
        address indexed owner,
        address indexed avatar,
        address target
    );
    event TransactionAdded(
        uint256 indexed queueNonce,
        bytes32 indexed txHash,
        address to,
        uint256 value,
        bytes data,
        Enum.Operation operation
    );
    event NewSigner(
        address newSigner
    );

    // transaction signer
    address internal _agentSigner;
    // execution hash authorized by signer
    mapping(bytes32 => bool) internal _authorized;

    uint256 public txCooldown;
    uint256 public txExpiration;
    uint256 public txNonce;
    uint256 public queueNonce;
    // Mapping of queue nonce to transaction hash.
    mapping(uint256 => bytes32) public txHash;
    // Mapping of queue nonce to creation timestamp.
    mapping(uint256 => uint256) public txCreatedAt;

    ///  _owner Address of the owner
    ///  _avatar Address of the avatar (e.g. a Gnosis Safe)
    ///  _target Address of the contract that will call exec function
    ///  _cooldown Cooldown in seconds that should be required after a transaction is proposed
    ///  _expiration Duration that a proposed transaction is valid for after the cooldown, in seconds (or 0 if valid forever)
    ///  There need to be at least 60 seconds between end of cooldown and expiration

    constructor(address _owner, address _avatar, address _target, uint256 _cooldown, uint256 _expiration) {

        bytes memory initParams =
            abi.encode(_owner, _avatar, _target, _cooldown, _expiration);

        setUp(initParams);
    }

    /// @dev initializes the contracts state
    /// @param initParams encoded contract state
    function setUp(bytes memory initParams) public initializer override {
        (
            address _owner,
            address _avatar,
            address _target,
            uint256 _cooldown,
            uint256 _expiration
        ) =
            abi.decode(
                initParams,
                (address, address, address, uint256, uint256)
            );
        __Ownable_init();
        require(_avatar != address(0), "Avatar can not be zero address");
        require(_target != address(0), "Target can not be zero address");
        require(
            _expiration == 0 || _expiration >= 60,
            "Expiration must be 0 or at least 60 seconds"
        );

        avatar = _avatar;
        target = _target;
        txExpiration = _expiration;
        txCooldown = _cooldown;

        transferOwnership(_owner);
        setupModules();

        emit DelaySetup(msg.sender, _owner, _avatar, _target);
    }

    function setupModules() internal {
        require(
            modules[SENTINEL_MODULES] == address(0),
            "setUpModules has already been called"
        );
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
    }

    // @dev Enforces that caller is a signer on our safe
    modifier onlySafeSigner() {
        require(ISafeSigner(avatar).isOwner(msg.sender) == true, "Invalid signer");
        _;
    }

    // @dev Assigns a new address as the signer
    // @param signer the new signer address
    function setAgentSigner(address agentSigner) public {
        if (_agentSigner != address(0)) {
            require(owner() == _msgSender(), "Must be Owner to reset agent signer!");
        }
        _agentSigner = agentSigner;
        emit NewSigner(agentSigner);
    }

    /// @dev Sets the cooldown before a transaction can be executed.
    /// @param cooldown Cooldown in seconds that should be required before the transaction can be executed
    /// @notice This can only be called by the owner
    function setTxCooldown(uint256 cooldown) public onlyOwner {
        txCooldown = cooldown;
    }

    /// @dev Sets the duration for which a transaction is valid.
    /// @param expiration Duration that a transaction is valid in seconds (or 0 if valid forever) after the cooldown
    /// @notice There need to be at least 60 seconds between end of cooldown and expiration
    /// @notice This can only be called by the owner
    function setTxExpiration(uint256 expiration) public onlyOwner {
        require(
            expiration == 0 || expiration >= 60,
            "Expiration must be 0 or at least 60 seconds"
        );
        txExpiration = expiration;
    }

    /// @dev Sets transaction nonce. Used to invalidate or skip transactions in queue.
    /// @param _nonce New transaction nonce
    /// @notice This can only be called by the owner
    function setTxNonce(uint256 _nonce) public onlyOwner {
        require(
            _nonce > txNonce,
            "New nonce must be higher than current txNonce"
        );
        require(_nonce <= queueNonce, "Cannot be higher than queueNonce");
        txNonce = _nonce;
    }

    /// @dev Sets transaction nonce. Used to invalidate or skip transactions in queue.
    /// @param _nonce New transaction nonce
    /// @notice This can only be called by a safe signer
    function quickVeto(uint256 _nonce) public onlySafeSigner {
        require(
            _nonce > txNonce,
            "New nonce must be higher than current txNonce"
        );
        require(_nonce <= queueNonce, "Cannot be higher than queueNonce");
        txNonce = _nonce;
    }

    /// @dev Authorizes a transaction if signature is from valid signer
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @param signature generated by signing the execution hash
    function authorizeTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        bytes calldata signature
    ) public {

        // generate the transaction's eth message execution hash
        bytes32 executionHash = getExecutionHash(to, value, data, operation);

        // recover the signer's address from the execution hash
        address agentSigner = executionHash.recover(signature);

        // enforce that our signer is valid
        require(agentSigner == _agentSigner, "Invalid signer");

        // add our execution hash to the authorized mapping
        _authorized[executionHash] = true;

        // enforce that our transaction is added to the queue
        require(execTransactionFromModule(to, value, data, operation), "Invalid transaction!");
    }

    /// @dev Adds a transaction to the queue (same as avatar interface so that this can be placed between other modules and the avatar).
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public override returns (bool success) {
        txHash[queueNonce] = getTransactionHash(to, value, data, operation);
        bytes32 executionHash = getExecutionHash(to, value, data, operation);
        require(_authorized[executionHash] == true, "Not an authorized transaction!");
        txCreatedAt[queueNonce] = block.timestamp;
        emit TransactionAdded(
            queueNonce,
            txHash[queueNonce],
            to,
            value,
            data,
            operation
        );
        delete(_authorized[txHash[queueNonce]]);
        queueNonce++;
        success = true;
    }

    /// @dev Executes the next transaction only if the cooldown has passed and the transaction has not expired
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @notice The txIndex used by this function is always 0
    function executeNextTx(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public {
        require(txNonce < queueNonce, "Transaction queue is empty");
        require(
            block.timestamp - txCreatedAt[txNonce] >= txCooldown,
            "Transaction is still in cooldown"
        );
        if (txExpiration != 0) {
            require(
                txCreatedAt[txNonce] + txCooldown + txExpiration >=
                    block.timestamp,
                "Transaction expired"
            );
        }
        require(
            txHash[txNonce] == getTransactionHash(to, value, data, operation),
            "Transaction hashes do not match"
        );
        txNonce++;
        require(exec(to, value, data, operation), "Module transaction failed");
    }

    /// @dev skips expired transactions by incrementing the transaction nonce
    function skipExpired() public {
        while (
            txExpiration != 0 &&
            txCreatedAt[txNonce] + txCooldown + txExpiration <
            block.timestamp &&
            txNonce < queueNonce
        ) {
            txNonce++;
        }
    }

    /// @dev retrieves the execution hash for a given function call
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, value, data, operation));
    }

    /// @dev retrieves the execution hash for a given function call
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    function getExecutionHash(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public pure returns (bytes32) {
        bytes32 transactionHash = keccak256(abi.encodePacked(to, value, data, operation));
        return transactionHash.toEthSignedMessageHash();
    }

    function getTxHash(uint256 _nonce) public view returns (bytes32) {
        return (txHash[_nonce]);
    }

    function getTxCreatedAt(uint256 _nonce) public view returns (uint256) {
        return (txCreatedAt[_nonce]);
    }

    function getAgentSigner() public view returns (address) {
        return _agentSigner;
    }
}