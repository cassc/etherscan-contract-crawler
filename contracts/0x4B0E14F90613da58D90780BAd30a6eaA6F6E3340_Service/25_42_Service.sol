// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IVesting.sol";
import "./interfaces/IInvoice.sol";
import "./interfaces/registry/IRegistry.sol";
import "./interfaces/ICustomProposal.sol";
import "./interfaces/registry/IRecordsRegistry.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev The main service contract through which the administrator manages the project, assigns roles to individual wallets, changes service commissions, and also through which the user creates pool contracts. Exists in a single copy.
contract Service is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IService
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    // CONSTANTS

    /// @notice Denominator for shares (such as thresholds)
    uint256 private constant DENOM = 100 * 10 ** 4;

    /// @notice Default admin  role
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    /// @notice User manager role
    bytes32 public constant SERVICE_MANAGER_ROLE = keccak256("USER_MANAGER");

    /// @notice User role
    bytes32 public constant WHITELISTED_USER_ROLE =
        keccak256("WHITELISTED_USER");

    /// @notice Executor role
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR");

    // STORAGE

    /// @dev Registry contract
    IRegistry public registry;

    /// @dev Pool beacon
    address public poolBeacon;

    /// @dev Token beacon
    address public tokenBeacon;

    /// @dev TGE beacon
    address public tgeBeacon;

    /// @dev There gets 0.1% (the value can be changed by the admin) of all Governance tokens from successful TGE
    address public protocolTreasury;

    /// @dev protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000
    uint256 public protocolTokenFee;

    /// @dev protocol token fee claimed for tokens
    mapping(address => uint256) public protolCollectedFee;

    /// @dev Proposal beacon
    ICustomProposal public customProposal;

    /// @dev Vesting contract
    IVesting public vesting;

    /// @dev TokenFactory contract
    IInvoice public invoice;

    /// @dev TokenFactory contract
    ITokenFactory public tokenFactory;

    /// @dev TGEFactory contract
    ITGEFactory public tgeFactory;

    // EVENTS

    /**
     * @dev Event emitted on pool creation.
     * @param pool Pool address
     * @param token Pool token address
     * @param tge Pool primary TGE address
     */
    event PoolCreated(address pool, address token, address tge);

    /**
     * @dev Event that emits when a pool is purchased.
     * @param pool Pool address
     * @param token Pool token address
     * @param tge Pool primary TGE address
     */
    event PoolPurchased(address pool, address token, address tge);

    /**
     * @dev Event emitted on protocol treasury change.
     * @param protocolTreasury Protocol treasury address
     */
    event ProtocolTreasuryChanged(address protocolTreasury);

    /**
     * @dev Event emitted on protocol token fee change.
     * @param protocolTokenFee Protocol token fee
     */
    event ProtocolTokenFeeChanged(uint256 protocolTokenFee);

    /**
     * @dev Event emitted on transferring collected fees.
     * @param to Transfer recepient
     * @param amount Amount of transferred ETH
     */
    event FeesTransferred(address to, uint256 amount);

    /**
     * @dev Event emitted on proposal cacellation by service owner.
     * @param pool Pool address
     * @param proposalId Pool local proposal id
     */
    event ProposalCancelled(address pool, uint256 proposalId);

    /**
     * @dev Event emitted on PoolBeacon change.
     * @param beacon Beacon address
     */
    event PoolBeaconChanged(address beacon);

    /**
     * @dev Event emitted on TGEBeacon change.
     * @param beacon Beacon address
     */
    event TGEBeaconChanged(address beacon);
    /**
     * @dev Event emitted on TokenBeacon change.
     * @param beacon Beacon address
     */
    event TokenBeaconChanged(address beacon);
    /**
     * @dev Event emitted on CustomPropsalProxy change.
     * @param proxy Proxy address
     */
    event CustomPropsalChanged(address proxy);
    /**
     * @dev Event emitted on InvoiceProxy change.
     * @param proxy Proxy address
     */
    event InvoiceChanged(address proxy);
    /**
     * @dev Event emitted on RegistryProxy change.
     * @param proxy Proxy address
     */
    event RegistryChanged(address proxy);
    /**
     * @dev Event emitted on TGEFactoryProxy change.
     * @param proxy Proxy address
     */
    event TGEFactoryChanged(address proxy);

    /**
     * @dev Event emitted on TokenFactoryProxy change.
     * @param proxy Proxy address
     */
    event TokenFactoryChanged(address proxy);

    /**
     * @dev Event emitted on VestingProxy change.
     * @param proxy Proxy address
     */
    event VestingChanged(address proxy);
    // MODIFIERS

    modifier onlyPool() {
        require(
            registry.typeOf(msg.sender) == IRecordsRegistry.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );
        _;
    }

    modifier onlyTGE() {
        require(
            registry.typeOf(msg.sender) == IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    modifier onlyRegistry() {
        require(
            msg.sender == address(registry),
            ExceptionsLibrary.NOT_REGISTRY
        );
        _;
    }

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function, can only be called once
     * @param registry_ Registry address
     * @param customProposal_ Custom proposals address
     * @param vesting_ Vesting address
     * @param poolBeacon_ Pool beacon
     * @param tokenBeacon_ Governance token beacon
     * @param tgeBeacon_ TGE beacon
     * @param protocolTokenFee_ Protocol token fee
     */
    function initialize(
        IRegistry registry_,
        ICustomProposal customProposal_,
        IVesting vesting_,
        address poolBeacon_,
        address tokenBeacon_,
        address tgeBeacon_,
        uint256 protocolTokenFee_
    ) external reinitializer(2) {
        require(
            address(registry_) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );
        require(poolBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(tokenBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(tgeBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        __Pausable_init();
        __ReentrancyGuard_init();

        registry = registry_;
        vesting = vesting_;
        poolBeacon = poolBeacon_;
        tokenBeacon = tokenBeacon_;
        tgeBeacon = tgeBeacon_;
        customProposal = customProposal_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SERVICE_MANAGER_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender);
        _setRoleAdmin(WHITELISTED_USER_ROLE, SERVICE_MANAGER_ROLE);

        setProtocolTreasury(address(this));
        setProtocolTokenFee(protocolTokenFee_);
    }

    /**
     * @dev Initializez factories for previously deployed service
     * @param tokenFactory_ TokenFactory address
     * @param tgeFactory_ TGEFactory address
     */
    function initializeFactories(
        ITokenFactory tokenFactory_,
        ITGEFactory tgeFactory_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) reinitializer(3) {
        tokenFactory = tokenFactory_;
        tgeFactory = tgeFactory_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Method for purchasing a pool by the user. Among the data submitted for input, there are jurisdiction and Entity Type
     * @param jurisdiction jurisdiction
     * @param entityType entityType
     */
    function purchasePool(
        uint256 jurisdiction,
        uint256 entityType,
        string memory trademark,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings
    ) external payable nonReentrant whenNotPaused {
        // Lock company
        IRegistry.CompanyInfo memory companyInfo = registry.lockCompany(
            jurisdiction,
            entityType
        );

        // Check fee
        require(
            msg.value == companyInfo.fee,
            ExceptionsLibrary.INCORRECT_ETH_PASSED
        );

        // Create pool
        IPool pool = IPool(getPoolAddress(companyInfo));

        // setNewOwnerWithSettings to pool contract
        pool.setNewOwnerWithSettings(msg.sender, trademark, governanceSettings);

        // Emit event
        emit PoolPurchased(address(pool), address(0), address(0));
    }

    // PUBLIC INDIRECT FUNCTIONS (CALLED THROUGH POOL OR REGISTRY)

    /**
     * @dev Add proposal to directory
     * @param proposalId Proposal ID
     */
    function addProposal(uint256 proposalId) external onlyPool whenNotPaused {
        registry.addProposalRecord(msg.sender, proposalId);
    }

    /**
     * @dev Add event to directory
     * @param eventType Event type
     * @param proposalId Proposal ID
     * @param metaHash Hash value of event metadata
     */
    function addEvent(
        IRegistry.EventType eventType,
        uint256 proposalId,
        string calldata metaHash
    ) external onlyPool whenNotPaused {
        registry.addEventRecord(
            msg.sender,
            eventType,
            address(0),
            proposalId,
            metaHash
        );
    }

    /**
     * @dev Method for purchasing a pool by the user. Among the data submitted for input, there are jurisdiction and Entity Type, which are used as keys to, firstly, find out if there is a company available for acquisition with such parameters among the Registry records, and secondly, to get the data of such a company if it exists, save them to the deployed pool contract, while recording the company is removed from the Registry. This action is only available to users who are on the global white list of addresses allowed before the acquisition of companies. At the same time, the Governance token contract and the TGE contract are deployed for its implementation.
     * @param companyInfo Company info
     */
    function createPool(
        IRegistry.CompanyInfo memory companyInfo
    ) external onlyRegistry nonReentrant whenNotPaused {
        // Create pool
        IPool pool = _createPool(companyInfo);

        // Initialize pool contract
        pool.initialize(companyInfo);

        // Emit event
        emit PoolCreated(address(pool), address(0), address(0));
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Transfer collected createPool protocol fees
     * @param to Transfer recipient
     */
    function transferCollectedFees(
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(to != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        uint256 balance = payable(address(this)).balance;
        (bool success, ) = payable(to).call{value: balance}("");
        require(success, ExceptionsLibrary.EXECUTION_FAILED);
        emit FeesTransferred(to, balance);
    }

    /**
     * @dev Set protocol collected token fee
     * @param _token token address
     * @param _protocolTokenFee fee collected
     */
    function setProtocolCollectedFee(
        address _token,
        uint256 _protocolTokenFee
    ) public onlyTGE {
        protolCollectedFee[_token] += _protocolTokenFee;
    }

    /**
     * @dev Assignment of the address to which the commission will be collected in the form of Governance tokens issued under successful TGE
     * @param _protocolTreasury Protocol treasury address
     */
    function setProtocolTreasury(
        address _protocolTreasury
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _protocolTreasury != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        protocolTreasury = _protocolTreasury;
        emit ProtocolTreasuryChanged(protocolTreasury);
    }

    /**
     * @dev Set protocol token fee
     * @param _protocolTokenFee protocol token fee percentage value with 4 decimals.
     * Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000.
     */
    function setProtocolTokenFee(
        uint256 _protocolTokenFee
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_protocolTokenFee <= DENOM, ExceptionsLibrary.INVALID_VALUE);

        protocolTokenFee = _protocolTokenFee;
        emit ProtocolTokenFeeChanged(_protocolTokenFee);
    }

    /**
     * @dev Sets new Registry contract
     * @param _registry registry address
     */
    function setRegistry(
        IRegistry _registry
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(_registry) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        registry = _registry;
        emit RegistryChanged(address(registry));
    }

    /**
     * @dev Sets new customProposal contract
     * @param _customProposal customProposal address
     */
    function setCustomProposal(
        ICustomProposal _customProposal
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(_customProposal) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        customProposal = _customProposal;
        emit CustomPropsalChanged(address(customProposal));
    }

    /**
     * @dev Sets new vesting
     * @param _vesting vesting address
     */
    function setVesting(
        IVesting _vesting
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(_vesting) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        vesting = _vesting;
        emit VestingChanged(address(vesting));
    }

    /**
     * @dev Sets new invoice contract
     * @param _invoice invoice address
     */
    function setInvoice(
        IInvoice _invoice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(_invoice) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        invoice = _invoice;
        emit InvoiceChanged(address(invoice));
    }

    /**
     * @dev Sets new pool beacon
     * @param beacon Beacon address
     */
    function setPoolBeacon(
        address beacon
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(beacon != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        poolBeacon = beacon;
        emit PoolBeaconChanged(address(poolBeacon));
    }

    /**
     * @dev Sets new token beacon
     * @param beacon Beacon address
     */
    function setTokenBeacon(
        address beacon
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(beacon != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tokenBeacon = beacon;
        emit TokenBeaconChanged(address(tokenBeacon));
    }

    /**
     * @dev Sets new TGE beacon
     * @param beacon Beacon address
     */
    function setTGEBeacon(
        address beacon
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(beacon != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tgeBeacon = beacon;
        emit TGEBeaconChanged(address(tgeBeacon));
    }

    /**
     * @dev Cancel pool's proposal
     * @param pool pool
     * @param proposalId proposalId
     */
    function cancelProposal(
        address pool,
        uint256 proposalId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IPool(pool).cancelProposal(proposalId);
        emit ProposalCancelled(pool, proposalId);
    }

    /**
     * @dev Pause service
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause service
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused()
        public
        view
        override(PausableUpgradeable, IService)
        returns (bool)
    {
        return super.paused();
    }

    /**
     * @dev Calculate minimum soft cap for token fee mechanism to work
     * @return softCap minimum soft cap
     */
    function getMinSoftCap() public view returns (uint256) {
        return (DENOM + protocolTokenFee - 1) / protocolTokenFee;
    }

    /**
     * @dev Сalculates protocol token fee for given token amount
     * @param amount Token amount
     * @return tokenFee
     */
    function getProtocolTokenFee(uint256 amount) public view returns (uint256) {
        require(amount >= getMinSoftCap(), ExceptionsLibrary.INVALID_VALUE);
        return (amount * protocolTokenFee + (DENOM - 1)) / DENOM;
    }

    /**
     * @dev Returns protocol token fee claimed for given token
     * @param token_ Token adress
     * @return token claimed
     */
    function getProtocolCollectedFee(
        address token_
    ) external view returns (uint256) {
        return protolCollectedFee[token_];
    }

    /**
     * @dev Return max hard cap accounting for protocol token fee
     * @param _pool pool to calculate hard cap against
     * @return Maximum hard cap
     */
    function getMaxHardCap(address _pool) public view returns (uint256) {
        if (
            registry.typeOf(_pool) == IRecordsRegistry.ContractType.Pool &&
            IPool(_pool).isDAO()
        ) {
            return
                IPool(_pool).getGovernanceToken().cap() -
                getProtocolTokenFee(IPool(_pool).getGovernanceToken().cap());
        }

        return type(uint256).max - getProtocolTokenFee(type(uint256).max);
    }

    /// @dev Service function that is used to check the correctness of TGE parameters (for the absence of conflicts between parameters)
    function validateTGEInfo(
        ITGE.TGEInfo calldata info,
        uint256 cap,
        uint256 totalSupplyWithReserves,
        IToken.TokenType tokenType
    ) external view {
        // Check unit of account
        if (info.unitOfAccount != address(0))
            require(
                IERC20Upgradeable(info.unitOfAccount).totalSupply() > 0,
                ExceptionsLibrary.INVALID_TOKEN
            );

        // Check hardcap
        require(
            info.hardcap >= info.softcap,
            ExceptionsLibrary.INVALID_HARDCAP
        );

        // Check vesting params
        vesting.validateParams(info.vestingParams);

        // Check remaining supply
        uint256 remainingSupply = cap - totalSupplyWithReserves;
        require(
            info.hardcap <= remainingSupply,
            ExceptionsLibrary.HARDCAP_OVERFLOW_REMAINING_SUPPLY
        );
        if (tokenType == IToken.TokenType.Governance) {
            require(
                info.hardcap + getProtocolTokenFee(info.hardcap) <=
                    remainingSupply,
                ExceptionsLibrary
                    .HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY
            );
        }
    }

    /**
     * @dev Get's create2 address for pool
     * @param info Company info
     * @return Pool contract address
     */
    function getPoolAddress(
        IRegistry.CompanyInfo memory info
    ) public view returns (address) {
        (bytes32 salt, bytes memory bytecode) = _getCreate2Data(info);
        return Create2Upgradeable.computeAddress(salt, keccak256(bytecode));
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Gets data for pool's create2
     * @param info Company info
     * @return salt Create2 salt
     * @return deployBytecode Deployed bytecode
     */
    function _getCreate2Data(
        IRegistry.CompanyInfo memory info
    ) internal view returns (bytes32 salt, bytes memory deployBytecode) {
        // Get salt
        salt = keccak256(
            abi.encode(info.jurisdiction, info.entityType, info.ein, 1)
        );

        // Get bytecode
        bytes memory proxyBytecode = type(BeaconProxy).creationCode;
        deployBytecode = abi.encodePacked(
            proxyBytecode,
            abi.encode(poolBeacon, "")
        );
    }

    /**
     * @dev Create pool contract and initialize it
     * @return pool Pool contract
     */
    function _createPool(
        IRegistry.CompanyInfo memory info
    ) internal returns (IPool pool) {
        // Create pool contract using Create2
        (bytes32 salt, bytes memory bytecode) = _getCreate2Data(info);
        pool = IPool(Create2Upgradeable.deploy(0, salt, bytecode));

        // Add pool contract to registry
        registry.addContractRecord(
            address(pool),
            IRecordsRegistry.ContractType.Pool,
            ""
        );
    }
}