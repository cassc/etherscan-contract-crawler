// SPDX-License-Identifier: No License
/**
 * @title Vendor Factory Contract
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./interfaces/IPositionTracker.sol";
import "./interfaces/IGenericPool.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IFeesManager.sol";
import "./utils/GenericUtils.sol";

contract PoolFactory is
    UUPSUpgradeable,
    PausableUpgradeable,
    IPoolFactory
{
    /* ========== CONSTANT VARIABLES ========== */
    bytes32 private constant APPROVE_LEND = 0x1000000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant APPROVE_COL = 0x0100000000000000000000000000000000000000000000000000000000000000;
    uint48 private constant HUNDRED_PERCENT = 100_0000;
    
    /* ========== STATE VARIABLES ========== */
    IFeesManager public feesManager;                      // Contract that keep track of pool rates. FeesManager.sol
    IPositionTracker public positionTracker;              // Contract that keep tracks of pools users participating in. PositionTracker.sol
    address public oracle;                                // Vendor oracle is used when token has on chain price source. Oracle.sol.
    address public treasury;                              // Vendor fees are sent to this address.
    address public firstResponder;                        // Can perform actions that are not behind time-lock, such as pausing.
    address public owner;                                 // Any configuration related actions, behind time-lock.

    mapping (PoolType => address) public implementations; // Allowed pool types.
    mapping (bytes32 => bool) public strategies;          // Allowed strategies. See docs on how those byte encodings are shaped.
    mapping(address => bool) public tokenAllowList;       // List of tokens allowed to be used in the pool
    mapping(address => bool) public pausedTokens;         // If returns true for lend or collateral asset of the pool, then pool will be paused.
    mapping(address => bool) public pausedPools;          // Pools that were paused by Vendor for some reason.
    mapping(address => bool) public pools;                // All pools deployed by this factory.
    mapping(address => uint48) public discount;           // Discount on vendor fee.
    // strategy => lend token => whether or not this lend token can be used with this strategy
    mapping(bytes32 => mapping(address => bool)) public allowedTokensForStrategy;

    uint48 public protocolFee;                            // Rate that Vendor charges pool creators in BPTS. 1% -> 10000
    bool public fullStop;                                 // If true, all pools and this Factory are paused.
    bool public allowUpgrade;                             // If true, pool operators can upgrade the implementation of the pool to a new allowed contract.
    bool public repaymentsPaused;                         // Repayments need to be paused separately.   
      
    address private _grantedOwner;                        // Used in 2-step owner transition.

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice                 Initialization function for the Factory Proxy.
    /// @param _oracle          Vendor Oracle aggregator that returns asset prices when required. See Oracle.sol.
    /// @param _protocolFee     Vendor fee that we charged from all borrowed assets. If vendor fee was 5% then when borrowing 100USDC users would get 95USDC.
    /// @param _treasury        Vendor fee goes to treasury.
    /// @param _firstResponder  Vendor controlled multisig for pausing the contracts.
    /// @param _tokenAllowList  Initial list of supported tokens.
    function initialize (
        address _oracle,
        uint48 _protocolFee,
        address _treasury,
        address _firstResponder,
        address[] calldata _tokenAllowList
    ) external initializer {
        __UUPSUpgradeable_init();
        __Pausable_init();
        if (
            _oracle == address(0) ||
            _treasury == address(0) ||
            _firstResponder == address(0)
        ) revert ZeroAddress();
        owner = msg.sender;
        oracle = _oracle;
        protocolFee = _protocolFee;
        treasury = _treasury;
        firstResponder = _firstResponder;
        for (uint256 i = 0; i < _tokenAllowList.length;) {
            tokenAllowList[_tokenAllowList[i]] = true;
            unchecked {
                ++i;
            } 
        }
    }

    /// @notice                 Entry-point for deploying all the pools.
    /// @param _params          Check the struct in the Types.sol.
    /// @param additionalData   Used when some extra data needs to be passed to pool initialization. Only used in some pool types.
    /// @return                 poolAddress of the newly deployed pool.
    function deployPool(
        DeploymentParameters calldata _params, // Had to wrap into a struct due to the issue with too many arguments.
        bytes calldata additionalData
    ) external whenNotPaused returns (address poolAddress) {
        if (fullStop) revert OperationsPaused();
        if (!tokenAllowList[_params.lendToken]) revert LendTokenNotSupported();
        if (!tokenAllowList[_params.colToken]) revert ColTokenNotSupported();
        if (_params.colToken == _params.lendToken) revert InvalidTokenPair();
        if (_params.lendRatio == 0) revert LendRatio0();
        if (_params.expiry < block.timestamp + 24 hours) revert InvalidExpiry();
        if (implementations[_params.poolType] == address(0)) revert ImplementationNotWhitelisted();
        if (_params.pauseTime < block.timestamp || _params.pauseTime > _params.expiry) revert InvalidPauseTime();
        if (_params.strategy != 0) _validateStrategy(_params.strategy, _params.lendToken, _params.colToken);

        poolAddress = _initializePool(_params, additionalData);
        pools[poolAddress] = true;
        
        feesManager.setPoolRates(poolAddress, _params.feeRatesAndType, _params.expiry, protocolFee);
        _setupPool(_params, poolAddress);
    }

    /// @notice                  Helper function that actually deploys the Proxy contract of the correct implementation.
    /// @param _params           Check the struct in the Types.sol.
    /// @param _additionalData   Used when some extra data needs to be passed to pool initialization. Only used in some pool types.
    /// @return                  lendingPool contains the address of the newly deployed pool.
    function _initializePool(DeploymentParameters calldata _params, bytes calldata _additionalData) private returns (address lendingPool) {
        // Construct factory parameters. Those parameters must be coming from factory.
        // Pool operators should not have ability to update those variables of the pool past deployment.
        FactoryParameters memory factorySettings = FactoryParameters(
            {
                feesManager: address(feesManager),
                oracle: oracle,
                treasury: treasury,
                posTracker: address(positionTracker),
                strategy: _params.strategy
            }
        );
        // Construct pool specific parameters. Those might be updated later depending on pool type.
        GeneralPoolSettings memory poolSettings = GeneralPoolSettings(
            {
                poolType: _params.poolType,
                owner: msg.sender,
                lendRatio: _params.lendRatio,
                colToken: IERC20(_params.colToken),
                lendToken: IERC20(_params.lendToken),
                feeRatesAndType: _params.feeRatesAndType,
                allowlist: _params.allowlist,
                expiry: _params.expiry,
                protocolFee: protocolFee - discount[msg.sender],
                ltv: _params.ltv,
                pauseTime: _params.pauseTime
            }
        );
        address impl = implementations[_params.poolType];
        lendingPool = address(
            new ERC1967Proxy(impl, 
                abi.encodeWithSignature(
                    "initialize(bytes,bytes,bytes)",
                    abi.encode(factorySettings),
                    abi.encode(poolSettings),
                    _additionalData
                )
            )
        );
        emit DeployPool(
            lendingPool, 
            msg.sender, 
            impl,
            factorySettings,
            poolSettings
        );      
    }

    /// @notice                 Additional actions that can be done depending on the pool type that should be done past deployment of the pool.
    /// @param _params          Check the struct in the Types.sol.
    /// @param _pool            Address of the freshly deployed pool contract.
    function _setupPool(DeploymentParameters calldata _params, address _pool) private {
        if (_params.poolType == PoolType.LENDING_ONE_TO_MANY){
            positionTracker.openLendPosition(msg.sender, _pool);
            if (_params.initialDeposit > 0){
                uint256 deposit = GenericUtils.safeTransferFrom(IERC20(_params.lendToken), msg.sender, address(this), _params.initialDeposit);
                IERC20(_params.lendToken).approve(_pool, deposit);
                IGenericPool(_pool).deposit(deposit);
            }
        } else if (_params.poolType == PoolType.BORROWING_ONE_TO_MANY){ 
            positionTracker.openBorrowPosition(msg.sender, _pool);
            if (_params.initialDeposit > 0){
                uint256 deposit = GenericUtils.safeTransferFrom(IERC20(_params.colToken), msg.sender, address(this), _params.initialDeposit);
                IERC20(_params.colToken).approve(_pool, deposit);
                IGenericPool(_pool).deposit(deposit);
            }
        }
    }

    /// @notice                 Validate if the strategy can be used with the selected tokens.
    /// @param _strategy        Encoding of the strategy.
    /// @param _lendToken       Lend token that is to be used.
    /// @param _colToken        Collateral token that is to be used.
    function _validateStrategy(bytes32 _strategy, address _lendToken, address _colToken) private view {
        if (!strategies[_strategy]) revert StrategyNotWhitelisted();
        if ((_strategy & APPROVE_LEND) == APPROVE_LEND) {
            if (!allowedTokensForStrategy[_strategy][_lendToken]) revert TokenNotSupportedWithStrategy();
        }
        if ((_strategy & APPROVE_COL) == APPROVE_COL) {
            if (!allowedTokensForStrategy[_strategy][_colToken]) revert TokenNotSupportedWithStrategy();
        }
    }

    /* ========== SETTERS ========== */

    /// @param _strategy       The key used to identify this strategy.
    /// @param _tokens         The tokens that can be used with this strategy key.
    /// @param _enabled        Boolean values denoting whether the provided token is whitelisted or blacklisted with the strategy key.
    function setAllowedTokensForStrategy(
        bytes32 _strategy, 
        address[] calldata _tokens, 
        bool[] calldata _enabled
    ) external {
        onlyOwner();
        if (_strategy == bytes32(0)) revert ZeroAddress();
        if (_tokens.length != _enabled.length) revert InvalidParameters();
        for (uint256 i = 0; i < _tokens.length;) {
            allowedTokensForStrategy[_strategy][_tokens[i]] = _enabled[i]; 
            unchecked {
                ++i;
            }
        }
    }

    /// @notice              Updates the oracle address.
    /// @param _oracle       The address of the oracle.
    function setOracle(address _oracle) external {
        onlyOwner();
        if (_oracle == address(0)) revert ZeroAddress();
        oracle = _oracle;
    }

    /// @notice                Updates treasury address.
    /// @param _treasury       The address of the treasury.
    function setTreasury(address _treasury) external {
        onlyOwner();
        if (_treasury == address(0)) revert ZeroAddress();
        treasury = _treasury;
    }

    /// @notice                   Updates fees manager address.
    /// @param _feesManager       The address of the fees manager.
    function setFeesManager(address _feesManager) external {
        onlyOwner();
        if (_feesManager == address(0)) revert ZeroAddress();
        feesManager = IFeesManager(_feesManager);
    }

    /// @notice                   Updates VENDOR fee.
    /// @param _protocolFee       Protocol fee percentage.
    function setProtocolFee(uint48 _protocolFee) external {
        onlyOwner();
        protocolFee = _protocolFee;
    }

    /// @notice                Sets a discount amount on the protocol fee that the provided deployer address will receive when deploying pools.
    /// @param _deployer       The address that the provided discount will be applied to.
    /// @param _discount       The discount amount as a percentage.
    function setDiscount(address _deployer, uint48 _discount) external {
        onlyOwner();
        if (_discount > protocolFee) revert InvalidParameters();
        discount[_deployer] = _discount;
    }

    /// @notice              Add or remove collateral from the allow list.
    /// @param _token        Address of the token to be either whitelisted or blacklisted from usage in protocol.
    /// @param _allowed      Determines whether the provided token is whitelisetd or blacklisted.
    function setTokenAllowList(address _token, bool _allowed) public {
        onlyOwner();
        tokenAllowList[_token] = _allowed;
    }

    /// @notice                    Updates the protocol's first responder address.
    /// @param _newResponder       Address of new first responder.
    function setFirstResponder(address _newResponder) external {
        onlyOwner();
        if (firstResponder == address(0)) revert ZeroAddress();
        firstResponder = _newResponder;
    }
    
    /// @notice                  Updates the position tracker address.
    /// @param _newTracker       Address of the new position tracker contract.
    function setPositionTracker(address _newTracker) external {
        onlyOwner();
        if (_newTracker == address(0)) revert ZeroAddress();
        positionTracker = IPositionTracker(_newTracker);
    }

    /* ========== UTILITY ========== */
    
    /// @notice                      Sets a new implementation contract for the provided pool type.
    /// @param _implementation       Address of the new pool implementation contract.
    /// @param _type                 Pool type to use with new implementation.
    function setImplementation(PoolType _type, address _implementation) external {
        onlyOwner();
        implementations[_type] = _implementation;
    }

    /// @notice                Gives factory owner the ability to whitelist or blacklist certain strategy keys.
    /// @param _strategy       The strategy key to be used.
    /// @param _enabled        Boolean value denoting whether the provided strategy key can be used.
    function setStrategy(bytes32 _strategy, bool _enabled) external {
        onlyOwner();
        if (_strategy == bytes32(0)) revert ZeroAddress();
        strategies[_strategy] = _enabled;
    }

    /// @notice                   Pauses the factory contract.
    /// @param _pauseEnable       Boolean value denoting whether the factory should be paused or unpaused.
    function setPauseFactory(bool _pauseEnable) public {
        onlyOwnerORFirstResponder();
        if (_pauseEnable) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @notice                            Pause/unpause all of the pools deployed by this factory.
    /// @param _factory                    Determins whether the factory should be paused.
    /// @param _generalFunctionality       Determins whether the factory's general functionality should be paused/unpaused.
    /// @param _repayments                 Determins whether repayments should be paused/unpaused.
    function setFullStop(bool _factory, bool _generalFunctionality, bool _repayments) external {
        onlyOwnerORFirstResponder();
        fullStop = _generalFunctionality;
        repaymentsPaused = _repayments;
        setPauseFactory(_factory);
    }

    /// @notice              Pause/unpause repayments as those are not paused by default.
    /// @param _paused       Determines whether repayments should be paused.
    function setRepaymentsPause(bool _paused) external {
        onlyOwnerORFirstResponder();
        repaymentsPaused = _paused;
    }

    /// @notice                 Pause/unpause a specific pool deployed by this factory.
    /// @param _pool            Address of individual pool.
    /// @param _paused          Determines whether pool should be paused/unpaused.
    function setPoolStop(address _pool, bool _paused) external {
        onlyOwnerORFirstResponder();
        pausedPools[_pool] = _paused;
    }

    /// @notice                 Pause/unpause all pools with a specific token as a lend or collateral asset deployed by this factory.
    /// @param _token           Address of token to be paused/unpaused.
    /// @param _paused          Determines whether token should be paused/unpaused.
    function setTokenStop(address _token, bool _paused) external {
        onlyOwnerORFirstResponder();
        pausedTokens[_token] = _paused;
        tokenAllowList[_token] = !_paused; // Also prevent new pools from being deployed with this token.
    }

    /// @notice                     Check if specific pool is paused by Vendor.
    /// @param _pool                Address of individual pool.
    /// @param _lendTokenAddr       Address of the lend token used in this pool.
    /// @param _colTokenAddr        Address of the collateral token used in this pool.
    /// @return                     Boolean value denoting whether the pool is paused at the provided _pool address.
    function isPoolPaused(address _pool, address _lendTokenAddr, address _colTokenAddr) external view returns (bool) {
        if (pausedTokens[_lendTokenAddr] || pausedTokens[_colTokenAddr]) return true;
        return fullStop || pausedPools[_pool];
    }

    /// @notice                  First step in a process of changing the owner of this Factory.
    /// @param newOwner          Proposed address for the new owner. This address will need to claim ownership.
    function grantOwnership(address newOwner) external virtual {
        onlyOwner();
        _grantedOwner = newOwner;
    }

    /// @notice                  Second step in a process of changing the owner of this Factory.
    function claimOwnership() public virtual {
        if (_grantedOwner != msg.sender) revert NotGranted();
        owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /// @notice                  Will allow the pool creators upgrade to an allowed implementation if different from implementation in use.
    /// @param _allowed          Wheather or not the upgrade is allowed.
    function setAllowUpgrade(bool _allowed) external {
        onlyOwner();
        allowUpgrade = _allowed;
    }

    // /* ========== MODIFIERS ========== */
    /// @notice                  Owner of the factory (Vendor).
    function onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }

    /// @notice                  Owner or first responder, just in case we have access to one of them faster.
    function onlyOwnerORFirstResponder() private view {
        if (msg.sender != firstResponder && msg.sender != owner)
            revert NotAuthorized();
    }

    /// @notice                  This function is called on the upgrade of the pool.
    /// @dev                     Upgrade can only happen to allowed implementation and by the owner of the pool.
    function _authorizeUpgrade(address /* newImplementation */)
        internal
        view
        override
        whenNotPaused
    {
        onlyOwner();
    }

}