/**
 *Submitted for verification at Etherscan.io on 2023-10-17
*/

// Sources flattened with hardhat v2.17.2 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @chainlink/contracts-ccip/src/v0.8/ccip/libraries/[email protected]

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

// End consumer library.
library Client {
  struct EVMTokenAmount {
    address token; // token address on the local chain.
    uint256 amount; // Amount of tokens.
  }

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source.
    uint64 sourceChainSelector; // Source chain selector.
    bytes sender; // abi.decode(sender) if coming from an EVM chain.
    bytes data; // payload sent in original message.
    EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
  }

  // If extraArgs is empty bytes, the default is 200k gas limit and strict = false.
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // extraArgs will evolve to support new features
  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit; // ATTENTION!!! MAX GAS LIMIT 4M FOR BETA TESTING
    bool strict; // See strict sequencing details below.
  }

  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}


// File @chainlink/contracts-ccip/src/v0.8/ccip/interfaces/[email protected]

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {
  /// @notice Called by the Router to deliver a message.
  /// If this reverts, any token transfers also revert. The message
  /// will move to a FAILED state and become available for manual execution.
  /// @param message CCIP Message
  /// @dev Note ensure you check the msg.sender is the OffRampRouter
  function ccipReceive(Client.Any2EVMMessage calldata message) external;
}


// File @chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/utils/introspection/[email protected]

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
    * @dev Returns true if this contract implements the interface defined by
    * `interfaceId`. See the corresponding
    * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    * to learn more about how these ids are created.
    *
    * This function call must use less than 30 000 gas.
    */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @chainlink/contracts-ccip/src/v0.8/ccip/applications/[email protected]

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
  address internal immutable i_router;

  constructor(address router) {
    if (router == address(0)) revert InvalidRouter(address(0));
    i_router = router;
  }

  /// @notice IERC165 supports an interfaceId
  /// @param interfaceId The interfaceId to check
  /// @return true if the interfaceId is supported
  function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
    return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  /// @inheritdoc IAny2EVMMessageReceiver
  function ccipReceive(Client.Any2EVMMessage calldata message) external virtual override onlyRouter {
    _ccipReceive(message);
  }

  /// @notice Override this function in your implementation.
  /// @param message Any2EVMMessage
  function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual;

  /////////////////////////////////////////////////////////////////////
  // Plumbing
  /////////////////////////////////////////////////////////////////////

  /// @notice Return the current router
  /// @return i_router address
  function getRouter() public view returns (address) {
    return address(i_router);
  }

  error InvalidRouter(address router);

  /// @dev only calls from the set router are accepted.
  modifier onlyRouter() {
    if (msg.sender != address(i_router)) revert InvalidRouter(msg.sender);
    _;
  }
}


// File @chainlink/contracts-ccip/src/v0.8/ccip/interfaces/[email protected]

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destChainSelector);
  error InsufficientFeeTokenAmount();
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainSelector The chain to check.
  /// @return supported is true if it is supported, false if not.
  function isChainSupported(uint64 chainSelector) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainSelector The chainSelector.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens);

  /// @param destinationChainSelector The destination chainSelector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns guaranteed execution fee for the specified message
  /// delivery to destination chain
  /// @dev returns 0 fee on invalid message.
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainSelector The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32);
}


// File @openzeppelin/contracts/utils/[email protected]

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/interface/IERC1271.sol

interface IERC1271 {
  // bytes4(keccak256("isValidSignature(bytes32,bytes)")
  // bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}


// File contracts/interface/IKlasterGatewayWallet.sol

interface IKlasterGatewayWallet {

    function execute(
        address destination,
        uint256 value,
        bytes memory data
    ) external returns (bool, address);

    function executeWithData(
        address destination,
        uint256 value,
        bytes memory data,
        bytes32 extraData
    ) external returns (bool, address);

}


// File contracts/gateway/KlasterGatewayWallet.sol

contract KlasterGatewayWallet is Ownable, IERC1271, IKlasterGatewayWallet {

    address public klasterGatewaySingleton;

    mapping (bytes32 => bool) public signatures;

    constructor(address _owner) {
        klasterGatewaySingleton = msg.sender;
        _transferOwnership(_owner);
    }

    function executeWithData(
        address destination,
        uint256 value,
        bytes memory data,
        bytes32 extraData
    ) external returns (bool, address) {
        if (destination == address(0)) { // contract deployment
            if (extraData == "") { // deploy using create()
                return (true, _performCreate(value, data));
            } else { // deploy using create2()
                return (true, _performCreate2(value, data, extraData));
            }
        } else { // transaction execution (use extra data as contract wallet signature as per ERC-1271)
            if (extraData != "") { signatures[extraData] = true; }
            return execute(destination, value, data);
        }
    }

    function execute(
        address destination,
        uint256 value,
        bytes memory data
    ) public returns (bool, address) {
        require(
            msg.sender == klasterGatewaySingleton || msg.sender == owner(),
            "Not an owner!"
        );
        bool result;
        uint dataLength = data.length;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return (result, address(0));
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue) {
        if (signatures[_hash]) {
            magicValue = 0x1626ba7e; // ERC1271: valid signature = bytes4(keccak256("isValidSignature(bytes32,bytes)")
        }
    }

    function _performCreate(
        uint256 value,
        bytes memory deploymentData
    ) internal returns (address newContract) {
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            newContract := create(value, add(deploymentData, 0x20), mload(deploymentData))
        }
        /* solhint-enable no-inline-assembly */
        require(newContract != address(0), "Could not deploy contract");
    }

    function _performCreate2(
        uint256 value,
        bytes memory deploymentData,
        bytes32 salt
    ) internal returns (address newContract) {
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            newContract := create2(value, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        /* solhint-enable no-inline-assembly */
        require(newContract != address(0), "Could not deploy contract");
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {}

}


// File contracts/interface/IKlasterGatewaySingleton.sol

interface IKlasterGatewaySingleton {

    /************************** EVENTS **************************/

    // Event emitted when a new gateway wallet instance has been deployed.
    event WalletDeploy(
        address indexed owner,
        address gatewayWallet
    );
    
    // Event emitted when a message is sent to another chain.
    event SendRTC(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        address indexed caller, // Wallet initiating the RTC
        uint64 destinationChainSelector, // The chain selector of the destination chain.
        uint64 execChainSelector, // The chain selector of the execution chain.
        address targetContract, // Remote contract to execute on dest chain
        bytes32 extraData, // Message hash used for ERC-1271 or salt used for create2
        address feeToken, // the token address used to pay CCIP fees.
        uint256 ccipfees, // The fees paid for sending the CCIP message.
        uint256 totalFees // Total fees (ccip + platform fee)
    );

    // Event emitted when a message is received from another chain.
    event ReceiveRTC(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed sourceChainSelector, // The chain selector of the destination chain.
        address caller, // Wallet initiating the RTC.
        address targetContract, // Remote contract to execute on dest chain,
        bytes32 extraData // Message hash used for ERC-1271 or salt used for create2
    );

    // Event emitted when any gateway wallet action gets executed
    event Execute(
        address indexed caller,
        address indexed gatewayWallet,
        address indexed destination,
        bool status,
        address contractDeployed,
        bytes32 extraData
    );

    /************************** WRITE **************************/

    function deploy(string memory salt) external returns (address);

    function batchExecute(
        uint64[][] memory execChainSelectors,
        string[] memory salt,
        address[] memory destination,
        uint256[] memory value,
        bytes[] memory data,
        uint256[] memory gasLimit,
        bytes32[] memory extraData
    ) external payable returns (bool[] memory, address[] memory, bytes32[] memory);

    function execute(
        uint64[] memory execChainSelectors,
        string memory salt,
        address destination,
        uint value,
        bytes memory data,
        uint256 gasLimit,
        bytes32 extraData
    ) external payable returns (bool, address, bytes32);

    /************************** READ **************************/

    function getDeployedWallets(address owner) external view returns (address[] memory);
    
    function calculateBatchExecuteFee(
        address caller,
        uint64[][] memory execChainSelectors,
        string[] memory salt,
        address[] memory destination,
        uint256[] memory value,
        bytes[] memory data,
        uint256[] memory gasLimit,
        bytes32[] memory extraData
    ) external view returns (uint256);

    function calculateExecuteFee(
        address caller,
        uint64[] memory execChainSelectors,
        string memory salt,
        address destination,
        uint value,
        bytes memory data,
        uint256 gasLimit,
        bytes32 extraData
    ) external view returns (uint256);

    function calculateAddress(address owner, string memory salt) external view returns (address);

    function calculateCreate2Address(
        address owner,
        string memory salt,
        bytes memory byteCode,
        bytes32 create2Salt
    ) external view returns (address);

}


// File contracts/interface/IOwnable.sol

interface IOwnable {
    function owner() external view returns (address);
}


// File contracts/gateway/KlasterGatewaySingleton.sol

contract KlasterGatewaySingleton is IKlasterGatewaySingleton, CCIPReceiver, Ownable {

    uint256 public feePercentage; // percentage fee on top of the ccip fees (modifiable by the owner)
    uint64 public thisChainSelector; // current chain selector
    uint64 public relayerChainSelector; // relayer chain selector (sepolia for testnet, eth for mainnet)
    
    mapping (address => bool) public deployed;
    mapping (address => string) public salts; // gateway wallet => salt
    mapping (address => address[]) public instances; // user => gateway wallet[]

    constructor(
        address _sourceRouter,
        uint64 _thisChainSelector,
        uint64 _relayerChainSelector,
        address _owner,
        uint256 _feePercentage
    ) CCIPReceiver(_sourceRouter) {
        thisChainSelector = _thisChainSelector;
        relayerChainSelector = _relayerChainSelector;
        feePercentage = _feePercentage;
        _transferOwnership(_owner);
    }

    function deploy(string memory salt) public override returns (address) {
       return _deploy(msg.sender, salt);
    }

    /***
     * OWNER FUNCTIONS (SENSITIVE)
     * 
     * Append only. Cant break anything or shut down the service.
     * KlasterGatewayWallet wallets will always work and in that sense it's permissionless.
     * The only two things an owner can affect and change post deployment are:
     *     1) Update platform fee - CAPPED TO 100% of the CCIP fee (!)
     *     2) Withdraw platform fee earnings
     */
    function updateFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "platform fee is capped to 100% of the CCIP fee");
        feePercentage = _feePercentage;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }


    /************ PUBLIC WRITE FUNCTIONS ************/

    function batchExecute(
        uint64[][] memory execChainSelectors,
        string[] memory salt,
        address[] memory destination,
        uint256[] memory value,
        bytes[] memory data,
        uint256[] memory gasLimit,
        bytes32[] memory extraData
    ) external payable override returns (bool[] memory success, address[] memory contractDeployed, bytes32[] memory messageId) {
        success = new bool[](execChainSelectors.length);
        contractDeployed = new address[](execChainSelectors.length);
        messageId = new bytes32[](execChainSelectors.length);
        for (uint256 i = 0; i < execChainSelectors.length; i++) {
            (success[i], contractDeployed[i], messageId[i]) = execute(
                execChainSelectors[i],
                salt[i],
                destination[i],
                value[i],
                data[i],
                gasLimit[i],
                extraData[i]
            );
        }
    }

    function execute(
        uint64[] memory execChainSelectors,
        string memory salt,
        address destination,
        uint256 value,
        bytes memory data,
        uint256 gasLimit,
        bytes32 extraData
    ) public payable override returns (bool success, address contractDeployed, bytes32 messageId) {
        
        if (destination != address(0) && extraData != "") { // if executing contract call (destination != 0) and extra data exists, then verify if the extra data is a valid signature
            require(
                IERC1271(msg.sender).isValidSignature(
                    extraData,
                    ""
                ) == 0x1626ba7e, // ERC1271: valid signature = bytes4(keccak256("isValidSignature(bytes32,bytes)")
                "Invalid signature."
            );
        }

        for (uint256 i = 0; i < execChainSelectors.length; i++) {
            (success, contractDeployed, messageId) = _execute(
                ExecutionData(
                    msg.sender,
                    execChainSelectors[i],
                    salt,
                    destination,
                    value,
                    data,
                    gasLimit,
                    extraData,
                    true
                )
            );
        }
    }

    /************ PUBLIC READ FUNCTIONS ************/

    function getDeployedWallets(address owner) external view override returns (address[] memory) {
        return instances[owner];
    }

    function calculateBatchExecuteFee(
        address caller,
        uint64[][] memory execChainSelectors,
        string[] memory salt,
        address[] memory destination,
        uint256[] memory value,
        bytes[] memory data,
        uint256[] memory gasLimit,
        bytes32[] memory extraData
    ) external view override returns (uint256 totalFee) {
        for (uint256 i = 0; i < execChainSelectors.length; i++) {
            totalFee += calculateExecuteFee(
                caller,
                execChainSelectors[i],
                salt[i],
                destination[i],
                value[i],
                data[i],
                gasLimit[i],
                extraData[i]
            );
        }
    }

    function calculateExecuteFee(
        address caller,
        uint64[] memory execChainSelectors,
        string memory salt,
        address destination,
        uint256 value,
        bytes memory data,
        uint256 gasLimit,
        bytes32 extraData
    ) public view override returns (uint256 totalFee) {
        for (uint256 i = 0; i < execChainSelectors.length; i++) {
            uint64 execChainSelector = execChainSelectors[i];
            if (execChainSelector != thisChainSelector) {
                // Get available lane    
                uint64 destChainSelector = _getDestChainSelector(execChainSelector);
        
                // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
                Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
                    address(this),
                    abi.encode(caller, execChainSelector, salt, destination, value, data, gasLimit, extraData),
                    address(0),
                    gasLimit
                );

                (, uint256 fee) = _getFees(destChainSelector, execChainSelector, evm2AnyMessage);
                totalFee += fee;
            }
        }
    }

    function calculateAddress(address owner, string memory salt) public view override returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), keccak256(abi.encodePacked(owner, salt)), keccak256(_getBytecode(owner))
            )
        );
        return address(uint160(uint(hash)));
    }

    function calculateCreate2Address(
        address owner,
        string memory salt,
        bytes memory byteCode,
        bytes32 create2Salt
    ) external view override returns (address) {
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                calculateAddress(owner, salt),
                create2Salt,
                keccak256(byteCode)
            )
        );
        return address(uint160(uint256(hash_)));
    }

    /************ INTERNAL FUNCTIONS ************/
    
    struct ExecutionData {
        address caller;
        uint64 execChainSelector;
        string salt;
        address destination;
        uint256 value;
        bytes data;
        uint256 gasLimit;
        bytes32 extraData;
        bool feeEnabled;
    }
    function _execute(
        ExecutionData memory execData
    ) internal returns (bool success, address contractDeployed, bytes32 messageId) {
        if (execData.execChainSelector == thisChainSelector) { // execute on this chain
            (success, contractDeployed) = _executeOnWallet(
                execData.caller,
                execData.salt,
                execData.destination,
                execData.value,
                execData.data,
                execData.extraData
            );
        } else { // remote execution on target chain via CCIP

            // Get available lane  
            uint64 destChainSelector = _getDestChainSelector(execData.execChainSelector);

            // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
            Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
                address(this),
                abi.encode(
                    execData.caller,
                    execData.execChainSelector,
                    execData.salt,
                    execData.destination,
                    execData.value,
                    execData.data,
                    execData.gasLimit,
                    execData.extraData
                ),
                address(0),
                execData.gasLimit
            );

            (uint256 ccipFees, uint256 totalFee) = _getFees(
                destChainSelector,
                execData.execChainSelector,
                evm2AnyMessage
            );

            // Take into account platform fee
            if (execData.feeEnabled) {
                require(msg.value >= totalFee, "Ether amount too low. Send more ether to execute call.");
            }
            
            success = true;
            messageId = IRouterClient(getRouter()).ccipSend{value: ccipFees}(
                destChainSelector,
                evm2AnyMessage
            );

            emit SendRTC(
                    messageId,
                    execData.caller,
                    destChainSelector,
                    execData.execChainSelector,
                    execData.destination,
                    execData.extraData,
                    address(0),
                    ccipFees,
                    totalFee
            );
        }
    }

    // executes given action on the callers gateway wallet
    function _executeOnWallet(
        address caller,
        string memory salt,
        address destination,
        uint256 value,
        bytes memory data,
        bytes32 extraData
    ) internal returns (bool status, address contractDeployed) {
        address walletInstanceAddress = calculateAddress(caller, salt);
        if (!deployed[walletInstanceAddress]) { _deploy(caller, salt); }
        
        IKlasterGatewayWallet walletInstance = IKlasterGatewayWallet(walletInstanceAddress);
        
        require(IOwnable(walletInstanceAddress).owner() == caller, "Not an owner!");
        (status, contractDeployed) = walletInstance.executeWithData(destination, value, data, extraData);
        
        emit Execute(caller, walletInstanceAddress, destination, status, contractDeployed, extraData);
    }

    // deploys new gateway wallet for given owner and salt
    function _deploy(address owner, string memory salt) private returns (address walletInstance) {
        require(!deployed[calculateAddress(owner, salt)], "Already deployed! Use different salt!");
        
        bytes memory bytecode = _getBytecode(owner);
        bytes32 calculatedSalt = keccak256(abi.encodePacked(owner, salt));
        assembly {
            walletInstance := create2(0, add(bytecode, 32), mload(bytecode), calculatedSalt)
        }
        deployed[walletInstance] = true;
        salts[walletInstance] = salt;
        instances[owner].push(walletInstance);
        
        emit WalletDeploy(owner, walletInstance);
    }

    // get the bytecode of the contract KlasterGatewayWallet with encoded constructor
    function _getBytecode(address owner) private pure returns (bytes memory) {
        bytes memory bytecode = type(KlasterGatewayWallet).creationCode;
        return abi.encodePacked(bytecode, abi.encode(owner));
    }

    // @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for sending arbitrary bytes cross chain.
    /// @param _receiver The address of the receiver.
    /// @param _message The bytes data to be sent.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @param _gasLimit Gas limit.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address _receiver,
        bytes memory _message,
        address _feeTokenAddress,
        uint256 _gasLimit
    ) internal pure returns (Client.EVM2AnyMessage memory) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: _message, // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array aas no tokens are transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: _gasLimit, strict: false})
            ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });
        return evm2AnyMessage;
    }

    /// handle received execution message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    )
        internal
        override
    {
        require(
            abi.decode(any2EvmMessage.sender, (address)) == address(this),
            "Only official KlasterGatewaySingleton can send CCIP messages."
        );

        (
            address caller,
            uint64 execChainSelector,
            string memory salt,
            address destination,
            uint256 value,
            bytes memory data,
            uint256 gasLimit,
            bytes32 extraData
        ) = abi.decode(
            any2EvmMessage.data,
            (
                address,
                uint64,
                string,
                address,
                uint256,
                bytes,
                uint256,
                bytes32
            )
        );

        _execute(ExecutionData(caller, execChainSelector, salt, destination, value, data, gasLimit, extraData, false));

        emit ReceiveRTC(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            caller,
            destination,
            extraData
        );
    }

    function _getFees(
        uint64 destChainSelector,
        uint64 execChainSelector,
        Client.EVM2AnyMessage memory message
    ) internal view returns (uint256 ccipFee, uint256 totalFee) {
        // Multiply fees by 2 if not a direct lane
        uint256 laneMultiplier = (destChainSelector == execChainSelector) ? 1 : 2;
        ccipFee = IRouterClient(getRouter()).getFee(destChainSelector, message);
        totalFee = (ccipFee + (ccipFee * feePercentage / 100)) * laneMultiplier;
    }

    function _directLaneExists(uint64 execChainSelector) internal view returns (bool) {
        return IRouterClient(getRouter()).isChainSupported(execChainSelector);
    }
    
    function _getDestChainSelector(uint64 execChainSelector) internal view returns (uint64 selector) {
        selector = _directLaneExists(execChainSelector) ? execChainSelector : relayerChainSelector;
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {}
}