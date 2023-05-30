// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface IGnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success, bytes memory returnData);

    function isOwner(address owner) external view returns (bool);
    function nonce() external view returns (uint256);
    function getThreshold() external view returns (uint256);
    function isModuleEnabled(address module) external view returns (bool);
    function enableModule(address module) external;
    function removeOwner(address prevOwner, address owner, uint256 _threshold) external;
    function swapOwner(address prevOwner, address oldOwner, address newOwner) external;
    function getOwners() external view returns (address[] memory);

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool);

    function setup(
        address[] memory _owners,
        uint256 _threshold,
        address to,
        bytes memory data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address paymentReceiver
    ) external;

    function addOwnerWithThreshold(address owner, uint256 _threshold) external;
}

interface IGnosisProxyFactory {
    event ProxyCreation(address proxy, address singleton);

    function calculateCreateProxyWithNonceAddress(address _singleton, bytes memory initializer, uint256 saltNonce)
        external
        returns (address proxy);

    function createProxy(address singleton, bytes memory data) external returns (address proxy);

    function createProxyWithCallback(address _singleton, bytes memory initializer, uint256 saltNonce, address callback)
        external
        returns (address proxy);

    function createProxyWithNonce(address _singleton, bytes memory initializer, uint256 saltNonce)
        external
        returns (address proxy);

    function proxyCreationCode() external pure returns (bytes memory);

    function proxyRuntimeCode() external pure returns (bytes memory);
}

interface IGnosisMultiSend {
    function multiSend(bytes memory transactions) external payable;
}

interface Types {
    enum CallType {
        STATICCALL,
        DELEGATECALL,
        CALL
    }

    struct Executable {
        CallType callType;
        address target;
        uint256 value;
        bytes data;
    }

    struct TokenRequest {
        address token;
        uint256 amount;
    }
}

library SafeHelper {
    error InvalidMultiSendCall(uint256);
    error InvalidMultiSendInput();
    error SafeExecTransactionFailed();

    /**
     * @notice Executes a transaction on a safe
     *
     * @dev Allows any contract using this library to execute a transaction on a safe
     *  Assumes the contract using this method is the owner of the safe
     *  Also assumes the safe is a single threshold safe
     *  This uses pre-validated signature scheme used by gnosis
     *
     * @param safe Safe address
     * @param target Target contract address
     * @param op Safe Operation type
     * @param data Transaction data
     */
    function _executeOnSafe(address safe, address target, Enum.Operation op, bytes memory data) internal {
        bool success = IGnosisSafe(safe).execTransaction(
            address(target), // to
            0, // value
            data, // data
            op, // operation
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            _generateSingleThresholdSignature(address(this)) // signatures
        );

        if (!success) revert SafeExecTransactionFailed();
    }

    /**
     * @notice Generates a pre-validated signature for a safe transaction
     * @dev Refer to https://docs.safe.global/learn/safe-core/safe-core-protocol/signatures#pre-validated-signatures
     * @param owner Owner of the safe
     */
    function _generateSingleThresholdSignature(address owner) internal pure returns (bytes memory) {
        bytes memory signatures = abi.encodePacked(
            bytes12(0), // Padding for signature verifier address
            bytes20(owner), // Signature Verifier
            bytes32(0), // Position of extra data bytes (last set of data)
            bytes1(hex"01") // Signature Type - 1 (presigned transaction)
        );
        return signatures;
    }

    /**
     * @notice Packs multiple executables into a single bytes array compatible with Safe's MultiSend contract
     * @dev Reference contract at https://github.com/safe-global/safe-contracts/blob/main/contracts/libraries/MultiSend.sol
     * @param _txns Array of executables to pack
     */
    function _packMultisendTxns(Types.Executable[] memory _txns) internal pure returns (bytes memory packedTxns) {
        uint256 len = _txns.length;
        if (len == 0) revert InvalidMultiSendInput();

        uint256 i = 0;
        do {
            // Enum.Operation.Call is 0
            uint8 call = uint8(Enum.Operation.Call);
            if (_txns[i].callType == Types.CallType.DELEGATECALL) {
                call = uint8(Enum.Operation.DelegateCall);
            } else if (_txns[i].callType == Types.CallType.STATICCALL) {
                revert InvalidMultiSendCall(i);
            }

            uint256 calldataLength = _txns[i].data.length;

            bytes memory encodedTxn = abi.encodePacked(
                bytes1(call), bytes20(_txns[i].target), bytes32(_txns[i].value), bytes32(calldataLength), _txns[i].data
            );

            if (i != 0) {
                // If not first transaction, append to packedTxns
                packedTxns = abi.encodePacked(packedTxns, encodedTxn);
            } else {
                // If first transaction, set packedTxns to encodedTxn
                packedTxns = encodedTxn;
            }

            unchecked {
                ++i;
            }
        } while (i < len);
    }
}

interface IAddressProviderService {
    /// @notice Returns the address of the AddressProvider
    function addressProviderTarget() external view returns (address);
}

/**
 * @title CoreAuth
 * @notice Contains core authorization logic
 */
contract CoreAuth {
    error NotGovernance(address);
    error NotPendingGovernance(address);
    error NullAddress();

    event GovernanceTransferRequested(address indexed previousGovernance, address indexed newGovernance);
    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);
    event GuardianUpdated(address indexed previousGuardian, address indexed newGuardian);
    event FundManagerUpdated(address indexed previousFundManager, address indexed newFundManager);

    /**
     * @notice Governance
     */
    address public governance;

    /**
     * @notice PendingGovernance - used for transferring governance in a 2 step process
     */
    address public pendingGovernance;

    /**
     * @notice Guardian - has authority to pause the safe module execution
     */
    address public guardian;

    /**
     * @notice FundManager - responsible for funding keeper bots and target for payable execution fees
     */
    address public fundManager;

    constructor(address _governance, address _guardian, address _fundManager) {
        _notNull(_governance);
        _notNull(_guardian);
        _notNull(_fundManager);
        governance = _governance;
        guardian = _guardian;
        fundManager = _fundManager;
    }

    /**
     * @notice Guardian setter
     */
    function setGuardian(address _newGuardian) external {
        _notNull(_newGuardian);
        _onlyGov();
        emit GuardianUpdated(guardian, _newGuardian);
        guardian = _newGuardian;
    }

    /**
     * @notice FundManager setter
     */
    function setFundManager(address _newFundManager) external {
        _notNull(_newFundManager);
        _onlyGov();
        emit FundManagerUpdated(fundManager, _newFundManager);
        fundManager = _newFundManager;
    }

    /**
     * @notice Governance setter
     */
    function setGovernance(address _newGovernance) external {
        _notNull(_newGovernance);
        _onlyGov();
        emit GovernanceTransferRequested(governance, _newGovernance);
        pendingGovernance = _newGovernance;
    }

    /**
     * @notice Governance accepter
     */
    function acceptGovernance() external {
        if (msg.sender != pendingGovernance) {
            revert NotPendingGovernance(msg.sender);
        }
        emit GovernanceTransferred(governance, msg.sender);
        governance = msg.sender;
        delete pendingGovernance;
    }

    /**
     * @notice helper function to check if msg.sender is governance
     */
    function _onlyGov() internal view {
        if (msg.sender != governance) revert NotGovernance(msg.sender);
    }

    /**
     * @notice helper function to check if address is null
     */
    function _notNull(address addr) internal pure {
        if (addr == address(0)) revert NullAddress();
    }
}

/**
 * @title AddressProvider
 * @notice Stores addresses of external contracts and core components
 */
contract AddressProvider is CoreAuth {
    enum RegistryKey {
        STRATEGY,
        SUBSCRIPTION,
        SUBACCOUNT,
        WALLET_ADAPTER,
        WALLET
    }

    error AddressProviderUnsupported();
    error AlreadyInitialised();
    error RegistryKeyNotFound(uint8);

    event RegistryInitialised(address indexed registry, uint8 indexed registryKey);

    constructor(address _governance, address _guardian, address _fundManager)
        CoreAuth(_governance, _guardian, _fundManager)
    {}

    /**
     * @dev External contract addresses for Gnosis Safe deployments
     *     Can be updated by governance
     */
    address public gnosisProxyFactory;
    address public gnosisSafeSingleton;
    address public gnosisFallbackHandler;
    address public gnosisMultiSend;

    /**
     * @dev Registry contracts containing state
     *     Cannot be updated
     */
    address public strategyRegistry;
    address public subscriptionRegistry;
    address public subAccountRegistry;
    address public walletAdapterRegistry;
    address public walletRegistry;

    /**
     * @dev Contract addresses for core components
     *     Can be updated by governance
     */
    address public botManager;
    address public brahRouter;
    address public priceFeedManager;
    address public safeDeployer;

    function setGnosisProxyFactory(address _gnosisProxyFactory) external {
        _notNull(_gnosisProxyFactory);
        _onlyGov();
        gnosisProxyFactory = (_gnosisProxyFactory);
    }

    function setGnosisSafeSingleton(address _gnosisSafeSingleton) external {
        _notNull(_gnosisSafeSingleton);
        _onlyGov();
        gnosisSafeSingleton = (_gnosisSafeSingleton);
    }

    /// @dev Fallback handler can be null
    function setGnosisSafeFallbackHandler(address _gnosisFallbackHandler) external {
        _onlyGov();
        gnosisFallbackHandler = (_gnosisFallbackHandler);
    }

    function setGnosisMultiSend(address _gnosisMultiSend) external {
        _notNull(_gnosisMultiSend);
        _onlyGov();
        gnosisMultiSend = (_gnosisMultiSend);
    }

    /**
     * @dev CAUTION! Changing BotManager will break existing tasks
     *     and wont allow deletion of previously created tasks
     */
    function setBotManager(address _botManager) external {
        _onlyGov();
        _supportsAddressProvider(_botManager);
        botManager = (_botManager);
    }

    /**
     * @dev CAUTION! Changing PriceFeedManager will require adding price
     *      feeds for all existing tokens
     */
    function setPriceFeedManager(address _priceFeedManager) external {
        _onlyGov();
        _supportsAddressProvider(_priceFeedManager);
        priceFeedManager = _priceFeedManager;
    }

    /**
     * @dev CAUTION! Changing BrahRouter will require all existing wallets
     *     to re register new BrahRouter as a safe module
     */
    function setBrahRouter(address _brahRouter) external {
        _onlyGov();
        _supportsAddressProvider(_brahRouter);
        brahRouter = (_brahRouter);
    }

    /**
     * @dev CAUTION! Changing SafeDeployer will loose any existing
     *     reserve subAccounts present
     */
    function setSafeDeployer(address _safeDeployer) external {
        _onlyGov();
        _supportsAddressProvider(_safeDeployer);
        safeDeployer = (_safeDeployer);
    }

    /**
     * @notice Initialises a registry contract
     * @dev Ensures that the registry contract is not already initialised
     *  CAUTION! Does not check if registry contract is valid or supports AddressProviderService
     *  This is to enable the registry contract to be initialised before their deployment
     * @param key RegistryKey
     * @param _newAddress Address of the registry contract
     */
    function initRegistry(RegistryKey key, address _newAddress) external {
        _onlyGov();
        if (key == RegistryKey.STRATEGY) {
            _firstInit(address(strategyRegistry));
            strategyRegistry = (_newAddress);
        } else if (key == RegistryKey.SUBSCRIPTION) {
            _firstInit(address(subscriptionRegistry));
            subscriptionRegistry = (_newAddress);
        } else if (key == RegistryKey.SUBACCOUNT) {
            _firstInit(address(subAccountRegistry));
            subAccountRegistry = (_newAddress);
        } else if (key == RegistryKey.WALLET_ADAPTER) {
            _firstInit(address(walletAdapterRegistry));
            walletAdapterRegistry = (_newAddress);
        } else if (key == RegistryKey.WALLET) {
            _firstInit(address(walletRegistry));
            walletRegistry = (_newAddress);
        } else {
            revert RegistryKeyNotFound(uint8(key));
        }

        emit RegistryInitialised(_newAddress, uint8(key));
    }

    /**
     * @notice Ensures that the new address supports the AddressProviderService interface
     * and is pointing to this AddressProvider
     */
    function _supportsAddressProvider(address _newAddress) internal view {
        if (IAddressProviderService(_newAddress).addressProviderTarget() != address(this)) {
            revert AddressProviderUnsupported();
        }
    }

    /**
     * @notice Ensures that the registry is not already initialised
     */
    function _firstInit(address _existingAddress) internal pure {
        if (_existingAddress != address(0)) revert AlreadyInitialised();
    }
}

/**
 * @title AddressProviderService
 * @notice Provides a base contract for services that require access to the AddressProvider
 * @dev This contract is designed to be inheritable by other contracts
 *  Provides quick and easy access to all contracts in Console Ecosystem
 */
abstract contract AddressProviderService is IAddressProviderService {
    error InvalidAddressProvider();
    error NotGovernance(address);
    error InvalidAddress();

    AddressProvider public immutable addressProvider;
    address public immutable strategyRegistry;
    address public immutable subscriptionRegistry;
    address public immutable subAccountRegistry;
    address public immutable walletAdapterRegistry;
    address public immutable walletRegistry;

    constructor(address _addressProvider) {
        if (_addressProvider == address(0)) revert InvalidAddressProvider();
        addressProvider = AddressProvider(_addressProvider);
        strategyRegistry = addressProvider.strategyRegistry();
        _notNull(strategyRegistry);
        subscriptionRegistry = addressProvider.subscriptionRegistry();
        _notNull(subscriptionRegistry);
        subAccountRegistry = addressProvider.subAccountRegistry();
        _notNull(subAccountRegistry);
        walletAdapterRegistry = addressProvider.walletAdapterRegistry();
        _notNull(walletAdapterRegistry);
        walletRegistry = addressProvider.walletRegistry();
        _notNull(walletRegistry);
    }

    /**
     * @inheritdoc IAddressProviderService
     */
    function addressProviderTarget() external view override returns (address) {
        return address(addressProvider);
    }

    /**
     * @notice Checks if msg.sender is governance
     */
    function _onlyGov() internal view {
        if (msg.sender != addressProvider.governance()) {
            revert NotGovernance(msg.sender);
        }
    }

    function _notNull(address _addr) internal pure {
        if (_addr == address(0)) revert InvalidAddress();
    }
}

interface IWalletAdapter is Types {
    function id() external view returns (uint8);

    function formatForWallet(address _wallet, Types.Executable memory _txn)
        external
        view
        returns (Types.Executable memory);

    function isAuthorized(address _wallet, address _user) external view returns (bool);

    function decodeReturnData(bytes memory data) external view returns (bool success, bytes memory returnData);
}

/**
 * @title WalletAdapterRegistry
 * @notice Stores address for wallet adapters of each wallet type
 */
contract WalletAdapterRegistry is AddressProviderService {
    error InvalidWalletId();

    event WalletAdapterRegistered(address indexed adapterAddress, uint8 indexed walletType);

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    mapping(uint8 walletType => address adapterAddress) public walletAdapter;

    /**
     * @notice Registers wallet adapter for a wallet type
     *
     * @dev Only governance can call this function
     *  Can be used to upgrade wallet adapter
     *
     * @param _adapter address of wallet adapter
     */
    function registerWalletAdapter(address _adapter) external {
        _onlyGov();
        uint8 _walletId = IWalletAdapter(_adapter).id();

        if (_walletId == 0) revert InvalidWalletId();

        walletAdapter[_walletId] = _adapter;

        emit WalletAdapterRegistered(_adapter, _walletId);
    }

    /**
     * @notice Checks if wallet adapter is registered for a wallet type
     * @param _walletType wallet type
     * @return true if wallet adapter is registered for a wallet type
     */
    function isWalletTypeSupported(uint8 _walletType) external view returns (bool) {
        if (walletAdapter[_walletType] == address(0)) return false;
        return true;
    }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/// @notice chainlink aggregator interface
interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/**
 * @title PriceFeedManager
 *   @notice Manages multiple tokens and their chainlink price feeds, for token price conversions
 */
contract PriceFeedManager is AddressProviderService {
    error NotUSDPriceFeed(address feed);
    error InvalidPriceFeed(address feed);
    error InvalidERC20Decimals(address token);
    error InvalidPriceFromRound(uint80 roundId);
    error InvalidWETHAddress();
    error PriceFeedStale();
    error TokenPriceFeedNotFound(address token);

    struct PriceFeedData {
        uint8 _tokenDecimals;
        address _address;
        uint64 _staleFeedThreshold;
    }

    /// @notice default stale threshold to price feeds on being added
    uint64 public constant DEFAULT_STALE_FEED_THRESHOLD = 90000;
    /// @notice address of ETH
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @notice address of WETH
    address public immutable WETH;

    /// @notice mapping of token address to data of price feed (_address, _staleFeedThreshold, _tokenDecimals)
    mapping(address token => PriceFeedData priceFeedData) public tokenPriceFeeds;

    constructor(address _addressProvider, address _weth) AddressProviderService(_addressProvider) {
        if (_weth == address(0)) revert InvalidWETHAddress();
        WETH = _weth;
    }

    /**
     * @notice Returns the pride feed data associated with a given token address
     * @param token address of token to get price feed data for
     * @return priceFeedData data of the price feed
     */
    function getPriceFeedData(address token) public view returns (PriceFeedData memory priceFeedData) {
        priceFeedData = tokenPriceFeeds[token];

        if (priceFeedData._address == address(0)) {
            revert TokenPriceFeedNotFound(token);
        }
    }

    /**
     * @notice Governance function to set the price feed for a token address
     * @param token address of a valid ERC20 token or native ETH
     * @param priceFeed address of a valid chainlink USD price feed
     * @param optionalStaleFeedThreshold optional stale feed threshold to set, defaults to 90000
     */
    function setTokenPriceFeed(address token, address priceFeed, uint64 optionalStaleFeedThreshold) external {
        _onlyGov();
        uint8 tokenDecimals = 0;

        try IAggregatorV3(priceFeed).decimals() returns (uint8 _decimals) {
            if (_decimals != 8) revert NotUSDPriceFeed(priceFeed);
        } catch {
            revert InvalidPriceFeed(priceFeed);
        }

        if (token != ETH) {
            try IERC20Metadata(token).decimals() returns (uint8 _decimals) {
                if (_decimals > 18) revert InvalidERC20Decimals(token);

                tokenDecimals = _decimals;
            } catch {
                revert InvalidERC20Decimals(token);
            }
        } else {
            tokenDecimals = 18;
        }

        if (optionalStaleFeedThreshold == 0) {
            optionalStaleFeedThreshold = DEFAULT_STALE_FEED_THRESHOLD;
        }

        try IAggregatorV3(priceFeed).latestRoundData() returns (
            uint80 roundId, int256 price, uint256, uint256 updatedAt, uint80 answeredInRound
        ) {
            _validateRound(roundId, answeredInRound, price, updatedAt, optionalStaleFeedThreshold);
        } catch {
            revert InvalidPriceFeed(priceFeed);
        }

        PriceFeedData storage priceFeedData = tokenPriceFeeds[token];
        priceFeedData._address = priceFeed;
        priceFeedData._staleFeedThreshold = optionalStaleFeedThreshold;
        priceFeedData._tokenDecimals = tokenDecimals;
    }

    /**
     * @notice Governance function to set the stake feed threshold of a given token
     * @param token address of token to modify stale feed threshold for
     * @param _staleFeedThreshold the stale feed threshold to set
     */
    function setTokenPriceFeedStaleThreshold(address token, uint64 _staleFeedThreshold) external {
        _onlyGov();

        PriceFeedData storage priceFeedData = tokenPriceFeeds[token];

        if (priceFeedData._address == address(0)) {
            revert TokenPriceFeedNotFound(token);
        }

        priceFeedData._staleFeedThreshold = _staleFeedThreshold;
    }

    /**
     * @notice Returns the token price given the token address
     * @param token address of token
     * @return price of token
     */
    function getTokenPrice(address token) external view returns (uint256 price) {
        (price,) = _getTokenData(token);
    }

    /**
     * @notice Returns the price of a token, in terms of another given token, provided both are added
     * @param amount amount of tokens in tokenX
     * @param tokenX address of token to convert from
     * @param tokenY address of token to convert to
     * @return price of tokenX amount in tokenY
     */
    function getTokenXPriceInY(uint256 amount, address tokenX, address tokenY) external view returns (uint256) {
        if ((tokenX == ETH || tokenX == WETH) && (tokenY == ETH || tokenY == WETH)) {
            return amount;
        }

        (uint256 tokenXPrice, uint8 tokenXDecimals) = _getTokenData(tokenX);
        (uint256 tokenYPrice, uint8 tokenYDecimals) = _getTokenData(tokenY);

        /// NOTE: returned price is adjusted to decimals of `tokenY`
        //  Representing decimal adjustment returning final amount in Y decimals
        //     (((     8      +     X       +       Y        )    -        8)   -      X)
        return (((tokenXPrice * amount * (10 ** tokenYDecimals)) / tokenYPrice) / (10 ** tokenXDecimals));
    }

    /**
     * @notice Internal helper to get the price and decimals of a token
     * @param token address of token
     * @return price of token
     * @return decimals of token
     */
    function _getTokenData(address token) internal view returns (uint256, uint8) {
        PriceFeedData memory priceFeedData = getPriceFeedData(token);

        (uint80 roundId, int256 _price,, uint256 updatedAt, uint80 answeredInRound) =
            IAggregatorV3(priceFeedData._address).latestRoundData();

        _validateRound(roundId, answeredInRound, _price, updatedAt, priceFeedData._staleFeedThreshold);

        return (uint256(_price), priceFeedData._tokenDecimals);
    }

    /**
     * @notice Internal helper to validate the latest round data of a chainlink price feed
     * @param roundId round id
     * @param answeredInRound round where latest returned data was answered
     * @param _latestPrice latest price from price feed
     * @param _lastUpdatedAt latest updated timestamp
     * @param _staleFeedThreshold stale feed threshold set for token
     */
    function _validateRound(
        uint80 roundId,
        uint80 answeredInRound,
        int256 _latestPrice,
        uint256 _lastUpdatedAt,
        uint256 _staleFeedThreshold
    ) internal view {
        if (_latestPrice <= 0) revert InvalidPriceFromRound(roundId);

        if (_lastUpdatedAt == 0) revert PriceFeedStale();

        if ((answeredInRound < roundId) || (block.timestamp - _lastUpdatedAt > _staleFeedThreshold)) {
            revert PriceFeedStale();
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToBytes32Map storage map) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToUintMap storage map, uint256 key, string memory errorMessage) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToUintMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToAddressMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(AddressToUintMap storage map) internal view returns (address[] memory) {
        bytes32[] memory store = keys(map._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToUintMap storage map, bytes32 key, uint256 value) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToUintMap storage map) internal view returns (bytes32[] memory) {
        bytes32[] memory store = keys(map._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

contract WalletRegistry is AddressProviderService {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    struct WalletData {
        uint8 walletType;
        address feeToken;
    }

    error WalletAlreadyExists(address);
    error UnsupportedWallet(address);
    error UnsupportedFeeToken(address);
    error TokenAlreadyAllowed(address);
    error WalletDoesntExist(address);

    event FeeTokenAdded(address indexed feeToken);
    event WalletRegistered(address indexed wallet, address indexed feeToken, uint8 walletType);
    event WalletDeRegistered(address indexed wallet);
    event WalletFeeTokenUpdated(address indexed wallet, address indexed feeToken);

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    EnumerableMap.AddressToUintMap allowedFeeTokens;
    mapping(address wallet => WalletData walletData) internal _walletDataMap;

    /**
     * @notice Adds a fee token to allowed fee tokens
     * @dev Can be used to add new fee tokens
     *  Once added, a fee token cannot be removed due to potential
     *  conflict with existing wallet fee tokens
     * @param _feeToken address of fee token
     */
    function addFeeToken(address _feeToken) external {
        _onlyGov();

        /// @dev internally reverts if price feed is not found
        PriceFeedManager(addressProvider.priceFeedManager()).getPriceFeedData(_feeToken);

        // Enumerable map should return false if feeToken is already present
        if (!allowedFeeTokens.set(_feeToken, allowedFeeTokens.length())) {
            revert TokenAlreadyAllowed(_feeToken);
        }

        emit FeeTokenAdded(_feeToken);
    }

    /**
     * @notice Returns if a fee token is allowed
     * @param _feeToken address of fee token
     * @return bool indicating if a fee token is allowed
     */
    function isFeeTokenAllowed(address _feeToken) external view returns (bool) {
        return allowedFeeTokens.contains(_feeToken);
    }

    /**
     * @notice Registers a wallet with wallet type and preferred fee token
     * @dev This assumes brahRouter already has permissions to execute on this user
     *  In case of gnosis safe, it already is added as a safe module on safe
     *  msg.sender is wallet here
     * @param _walletType wallet type
     * @param _feeToken address of fee token
     */
    function registerWallet(uint8 _walletType, address _feeToken) external {
        if (isWallet(msg.sender)) revert WalletAlreadyExists(msg.sender);

        //checking if walletType is supported
        if (!WalletAdapterRegistry(walletAdapterRegistry).isWalletTypeSupported(_walletType)) {
            revert UnsupportedWallet(msg.sender);
        }

        _setFeeToken(msg.sender, _feeToken);
        _setWalletType(msg.sender, _walletType);

        emit WalletRegistered(msg.sender, _feeToken, _walletType);
    }

    /**
     * @notice De-registers a wallet
     * @dev Can only be called by wallet itself
     *  CAUTION: Calling this will cause console to be unusable
     *  and will break any existing subscriptions
     *  Funds can still be recovered from subaccounts
     *
     *  A user can deregister their wallet and register
     *  their wallet again with a different wallet type
     *  to change their wallet type
     */
    function deRegisterWallet() external {
        if (!isWallet(msg.sender)) revert WalletDoesntExist(msg.sender);
        delete _walletDataMap[msg.sender];
        emit WalletDeRegistered(msg.sender);
    }

    /**
     * @notice Sets fee token for wallet
     * @dev Can only be called by wallet itself
     * @param _token address of fee token
     */
    function setFeeToken(address _token) external {
        if (!isWallet(msg.sender)) revert WalletDoesntExist(msg.sender);
        _setFeeToken(msg.sender, _token);
        emit WalletFeeTokenUpdated(msg.sender, _token);
    }

    /**
     * @notice Checks if wallet is registered
     * @param _wallet address of wallet
     * @return bool
     */
    function isWallet(address _wallet) public view returns (bool) {
        WalletData storage walletData = _walletDataMap[_wallet];
        if (walletData.walletType == 0 || walletData.feeToken == address(0)) {
            return false;
        }
        return true;
    }

    /**
     * @notice Fetches wallet type for wallet
     * @param _wallet wallet address
     * @return uint8 wallet type
     */
    function walletType(address _wallet) external view returns (uint8) {
        return _walletDataMap[_wallet].walletType;
    }

    /**
     * @notice Fetches fee token for wallet
     * @param _wallet wallet address
     * @return address fee token
     */
    function walletFeeToken(address _wallet) external view returns (address) {
        return _walletDataMap[_wallet].feeToken;
    }

    /**
     * @notice sets wallet type
     */
    function _setWalletType(address _wallet, uint8 _walletType) private {
        _walletDataMap[_wallet].walletType = _walletType;
    }

    /**
     * @notice validates and sets fee token
     */
    function _setFeeToken(address _wallet, address _feeToken) internal {
        if (!allowedFeeTokens.contains(_feeToken)) {
            revert UnsupportedFeeToken(_feeToken);
        }
        _walletDataMap[_wallet].feeToken = _feeToken;
    }
}

/**
 * @title SafeWalletAdapter
 * @notice This contract implements the IWalletAdapter interface for Gnosis Safe wallets.
 * @dev This adapter enables the integration of Gnosis Safe wallets with other contracts.
 */
contract SafeWalletAdapter is IWalletAdapter {
    // Custom error for handling invalid operation enums
    error UnableToParseOperation();

    // Wallet adapter ID
    // @dev Do NOT change the ID of SafeWalletAdapter from 1.
    uint8 public constant override id = 1;

    /**
     * @notice Formats a transaction for a Gnosis Safe wallet.
     * @param _wallet Address of the Gnosis Safe wallet.
     * @param _txn Transaction to be formatted.
     * @return formattedTxn Formatted transaction for the Gnosis Safe wallet.
     */
    function formatForWallet(address _wallet, Types.Executable memory _txn)
        external
        pure
        override
        returns (Types.Executable memory formattedTxn)
    {
        // Create a formatted transaction executable by a safe module
        formattedTxn = Types.Executable({
            callType: CallType.CALL,
            target: _wallet,
            value: 0,
            data: abi.encodeCall(
                IGnosisSafe.execTransactionFromModuleReturnData,
                (_txn.target, _txn.value, _txn.data, parseOperationEnum(_txn.callType))
                )
        });
    }

    /**
     * @notice Decodes the return data of a transaction.
     * @param data The return data to be decoded.
     * @return success Boolean indicating if the transaction was successful.
     * @return returnData Decoded return data.
     */
    function decodeReturnData(bytes memory data)
        external
        pure
        override
        returns (bool success, bytes memory returnData)
    {
        (success, returnData) = abi.decode(data, (bool, bytes));
    }

    /**
     * @notice Checks if a user is authorized for a Gnosis Safe wallet.
     * @param _wallet Address of the Gnosis Safe wallet.
     * @param _user Address of the user to be checked for authorization.
     * @return True if the user is authorized, false otherwise.
     */
    function isAuthorized(address _wallet, address _user) external view override returns (bool) {
        // Return false if the wallet threshold is greater than 1
        if (IGnosisSafe(_wallet).getThreshold() > 1) return false;
        // Return true if the user is an owner of the Gnosis Safe wallet
        return IGnosisSafe(_wallet).isOwner(_user);
    }

    /**
     * @notice Converts a CallType enum to an Operation enum.
     * @dev Reverts with UnableToParseOperation error if the CallType is not supported.
     * @param callType The CallType enum to be converted.
     * @return operation The converted Operation enum.
     */
    function parseOperationEnum(CallType callType) public pure returns (Enum.Operation operation) {
        if (callType == CallType.DELEGATECALL) {
            operation = Enum.Operation.DelegateCall;
        } else if (callType == CallType.CALL) {
            operation = Enum.Operation.Call;
        } else {
            revert UnableToParseOperation();
        }
    }
}

/**
 * @title SafeDeployer
 * @notice This contract is responsible for deploying and configuring Gnosis Safe wallets.
 * @dev It supports deployment of console accounts and sub accounts,
 *  as well as maintaining a reserve of sub accounts
 *  The reserve subaccounts can be deployed in advance by anyone
 *  and serve as a mechanism to subsidize the cost of deploying new
 *  sub accounts and subscribing to strategies
 */
contract SafeDeployer is AddressProviderService {
    /**
     * @notice Emitted after the brah console is deployed for the owner.
     * @param owner The user address.
     * @param consoleAddress The console-safe deployed for user.
     */
    event brahConsoleDeployed(address indexed owner, address indexed consoleAddress);

    /**
     * @notice Emitted after a sub account is deployed for the console.
     * @param consoleAddress The console-safe address.
     * @param subAccountAddress The sub account deployed for console.
     */
    event subAccountAllocated(address indexed consoleAddress, address indexed subAccountAddress);

    error InvalidOwner();
    error OnlySubAccountRegistry();
    error OnlyOwner();

    string public constant VERSION = "1.04";

    address[] public subAccountReserve;

    mapping(address owner => uint96 safeCount) public ownerSafeCount;

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    /**
     * @notice Deploys a console account for a user.
     *
     * @dev The console account in this case is a Gnosis Safe wallet.
     *  The console account is deployed with the user as the owner.
     *  BrahRouter is enabled as a safe module on the console account.
     *
     * @param _owner The address of the user.
     * @param _feeToken The address of the fee token.
     * @return The address of the deployed console account.
     */
    function deployConsoleAccount(address _owner, address _feeToken) external returns (address) {
        if (_owner != msg.sender) {
            revert OnlyOwner();
        }

        address safe = _createSafe(_owner);
        _setupSafeAsConsoleAccount(safe, _owner, _feeToken);

        emit brahConsoleDeployed(_owner, safe);
        return (safe);
    }

    /**
     * @notice Deploy reserve sub accounts.
     *
     *  @dev Can be used to deploy reserve sub accounts in batches.
     *  Useful when gasprice is low and we want to
     *  subsidize the cost of subscribing to deployments
     *
     * @param n The number of sub accounts to be deployed.
     */
    function deployReserveSubAccounts(uint256 n) external {
        uint256 idx = 0;
        while (idx < n) {
            subAccountReserve.push(_deployReserveSubAccount());
            unchecked {
                ++idx;
            }
        }
    }

    /**
     * @notice returns an array of the current reserve subAccounts
     *   @return list of reserve subAccount addresses
     */
    function getReserveSubAccounts() external view returns (address[] memory) {
        return subAccountReserve;
    }

    /**
     * @notice Allocate a fresh sub account.
     *
     * @dev Allocates a fresh sub account from the reserve.
     *  If no reserve sub accounts are available, deploys a new one.
     *  If a reserve sub account is available, transfers ownership to the wallet.
     *  Enables wallet as a safe module on the sub account.
     *  Subaccount returned should be equivalent to deploying a new sub account.
     *
     * @param _wallet The address of the main Safe.
     * @return subAccount address of the allocated sub account.
     */
    function allocateOrDeployFreshSubAccount(address _wallet) external returns (address subAccount) {
        // Only the sub account registry can call this method during createSubscription
        _onlySubAccountRegistry();

        // Checking if any reserve sub accounts are available
        uint256 subAccountsAvailable = subAccountReserve.length;

        // If reserve sub accounts are available, allocate one
        if (subAccountsAvailable > 0) {
            unchecked {
                subAccount = subAccountReserve[subAccountsAvailable - 1];
            }
            subAccountReserve.pop();

            Types.Executable[] memory transferOwnershipExecs = new Types.Executable[](2);

            // Enable mainSafe as a module on the sub account
            transferOwnershipExecs[0] = Types.Executable({
                callType: Types.CallType.CALL,
                target: subAccount,
                value: 0,
                data: abi.encodeCall(IGnosisSafe.enableModule, (_wallet))
            });
            // Replace the owner of the sub account with the mainSafe
            transferOwnershipExecs[1] = Types.Executable({
                callType: Types.CallType.CALL,
                target: subAccount,
                value: 0,
                data: abi.encodeCall(IGnosisSafe.swapOwner, (address(0x1), address(this), _wallet))
            });

            bytes memory multiSendCalldata = SafeHelper._packMultisendTxns(transferOwnershipExecs);

            // Execute the multisend transaction
            SafeHelper._executeOnSafe(
                subAccount,
                addressProvider.gnosisMultiSend(),
                Enum.Operation.DelegateCall,
                abi.encodeCall(IGnosisMultiSend.multiSend, multiSendCalldata)
            );
        } else {
            // If no reserve sub accounts are available, deploy a new sub account
            subAccount = _deploySubAccount(_wallet);
        }

        emit subAccountAllocated(_wallet, subAccount);
    }

    /**
     * @notice Internal function to deploy a reserve sub account.
     * @return The address of the deployed reserve sub account.
     */
    function _deployReserveSubAccount() internal returns (address) {
        address safe = _createSafe(address(this));
        _setupSafeAsReserveSubAccount(safe);
        return (safe);
    }

    /**
     * @notice Internal function to deploy a sub account.
     * @param _owner The address of the owner.
     * @return The address of the deployed sub account.
     */
    function _deploySubAccount(address _owner) internal returns (address) {
        address safe = _createSafe(_owner);
        _setupSafeAsSubAccount(safe, _owner);

        return (safe);
    }

    /**
     * @notice Internal function to create a new Gnosis Safe.
     * @param _owner The address of the Safe owner.
     * @return The address of the created Gnosis Safe.
     */
    function _createSafe(address _owner) internal returns (address) {
        address gnosisProxyFactory = addressProvider.gnosisProxyFactory();
        address gnosisSafeSingleton = addressProvider.gnosisSafeSingleton();

        address safe = IGnosisProxyFactory(gnosisProxyFactory).createProxyWithNonce(
            gnosisSafeSingleton, bytes(""), _genNonce(_owner)
        );
        return safe;
    }

    /**
     * @notice Internal function to setup a Safe as a console account.
     * @param safe The address of the Gnosis Safe.
     * @param _owner The address of the Safe owner.
     * @param _feeToken The address of the fee token.
     */
    function _setupSafeAsConsoleAccount(address safe, address _owner, address _feeToken) internal {
        address[] memory owners = new address[](1);
        owners[0] = (_owner);

        Types.Executable[] memory txns = new Types.Executable[](2);

        // Enable BrahRouter as safe module on Console Account
        txns[0] = Types.Executable({
            callType: Types.CallType.CALL,
            target: address(safe),
            value: 0,
            data: abi.encodeCall(IGnosisSafe.enableModule, (addressProvider.brahRouter()))
        });

        // Register console account with WalletRegistry
        txns[1] = Types.Executable({
            callType: Types.CallType.CALL,
            target: walletRegistry,
            value: 0,
            data: abi.encodeCall(
                WalletRegistry.registerWallet,
                (
                    1, // Safe Wallet Adapter ID
                    _feeToken // Fee token
                )
                )
        });

        // Setup safe with single threshold and multi-send
        IGnosisSafe(safe).setup(
            owners,
            1,
            addressProvider.gnosisMultiSend(),
            abi.encodeCall(IGnosisMultiSend.multiSend, (SafeHelper._packMultisendTxns(txns))),
            addressProvider.gnosisFallbackHandler(),
            address(0),
            0,
            address(0)
        );
    }

    /**
     * @notice Internal function to setup a Safe as a sub account.
     * @param safe The address of the Gnosis Safe.
     * @param _wallet The address of the Safe owner.
     */
    function _setupSafeAsSubAccount(address safe, address _wallet) internal {
        address[] memory owners = new address[](1);
        owners[0] = (_wallet);

        Types.Executable[] memory txns = new Types.Executable[](1);
        txns[0] = Types.Executable({
            callType: Types.CallType.CALL,
            target: address(safe),
            value: 0,
            data: abi.encodeCall(IGnosisSafe.enableModule, (_wallet))
        });

        // Cheaper to execute single txn via multisend rather than execTransaction
        IGnosisSafe(safe).setup(
            owners,
            1,
            addressProvider.gnosisMultiSend(),
            abi.encodeCall(IGnosisMultiSend.multiSend, (SafeHelper._packMultisendTxns(txns))),
            addressProvider.gnosisFallbackHandler(),
            address(0),
            0,
            address(0)
        );
    }

    /**
     * @notice Internal function to setup a Safe as a reserve sub account.
     *
     * @dev Setups a safe as a reserve sub account
     *  A reserve sub account is owned by the Safe Deployer
     *
     * @param safe The address of the Gnosis Safe.
     */
    function _setupSafeAsReserveSubAccount(address safe) internal {
        address[] memory owners = new address[](1);

        // Reserve sub accounts are owned by the Safe Deployer
        owners[0] = (address(this));

        IGnosisSafe(safe).setup(
            owners, 1, address(0), bytes(""), addressProvider.gnosisFallbackHandler(), address(0), 0, address(0)
        );
    }

    /**
     * @notice Internal function to get the nonce of a user's safe deployment
     * @param _user address of owner of the safe.
     * @return The nonce of the user's safe deployment.
     */
    function _genNonce(address _user) internal returns (uint256) {
        uint96 currentNonce = ownerSafeCount[_user]++;
        return uint256(keccak256(abi.encodePacked(_user, currentNonce, VERSION)));
    }

    function _onlySubAccountRegistry() internal view {
        if (msg.sender != subAccountRegistry) revert OnlySubAccountRegistry();
    }
}