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
import "./interfaces/registry/IRegistry.sol";
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
    uint256 private constant DENOM = 100 * 10**4;

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

    /// @dev Registry address
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

    // EVENTS

    /**
     * @dev Event emitted on pool creation.
     * @param pool Pool address
     * @param token Pool token address
     * @param tge Pool primary TGE address
     */
    event PoolCreated(address pool, address token, address tge);

    /**
     * @dev Event emitted on creation of secondary TGE.
     * @param pool Pool address
     * @param tge Secondary TGE address
     * @param token Preference token address
     */
    event SecondaryTGECreated(address pool, address tge, address token);

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

    // MODIFIERS

    modifier onlyPool() {
        require(
            registry.typeOf(msg.sender) == IRecordsRegistry.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );
        _;
    }

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once
     * @param registry_ Registry address
     * @param poolBeacon_ Pool beacon
     * @param tokenBeacon_ Governance token beacon
     * @param tgeBeacon_ TGE beacon
     * @param protocolTokenFee_ Protocol token fee
     */
    function initialize(
        IRegistry registry_,
        address poolBeacon_,
        address tokenBeacon_,
        address tgeBeacon_,
        uint256 protocolTokenFee_
    ) external initializer {
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
        poolBeacon = poolBeacon_;
        tokenBeacon = tokenBeacon_;
        tgeBeacon = tgeBeacon_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SERVICE_MANAGER_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender);
        _setRoleAdmin(WHITELISTED_USER_ROLE, SERVICE_MANAGER_ROLE);

        setProtocolTreasury(address(this));
        setProtocolTokenFee(protocolTokenFee_);
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Method for purchasing a pool by the user. Among the data submitted for input, there are jurisdiction and Entity Type, which are used as keys to, firstly, find out if there is a company available for acquisition with such parameters among the Registry records, and secondly, to get the data of such a company if it exists, save them to the deployed pool contract, while recording the company is removed from the Registry. This action is only available to users who are on the global white list of addresses allowed before the acquisition of companies. At the same time, the Governance token contract and the TGE contract are deployed for its implementation.
     * @param pool Pool address. If not address(0) - creates new token and new primary TGE for an existing pool.
     * @param tokenCap Pool token cap
     * @param tokenSymbol Pool token symbol
     * @param tgeInfo Pool TGE parameters
     * @param jurisdiction Pool jurisdiction
     * @param entityType Company entity type
     * @param governanceSettings Governance setting parameters
     * @param trademark Pool trademark
     * @param metadataURI Metadata URI
     */
    function createPool(
        IPool pool,
        uint256 tokenCap,
        string memory tokenSymbol,
        ITGE.TGEInfo memory tgeInfo,
        uint256 jurisdiction,
        uint256 entityType,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings,
        string memory trademark,
        string memory metadataURI
    ) external payable nonReentrant whenNotPaused {
        // Check token cap
        require(tokenCap >= 1 ether, ExceptionsLibrary.INVALID_CAP);

        // Add protocol fee to token cap
        tokenCap += getProtocolTokenFee(tokenCap);

        if (address(pool) == address(0)) {
            // Check that user is whitelisted and remove him from whitelist
            _checkRole(WHITELISTED_USER_ROLE);
            _revokeRole(WHITELISTED_USER_ROLE, msg.sender);

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
            pool = _createPool(companyInfo);

            // Initialize pool contract
            pool.initialize(
                msg.sender,
                trademark,
                governanceSettings,
                companyInfo
            );
        } else {
            // Check that pool is valid
            require(
                registry.typeOf(address(pool)) ==
                    IRecordsRegistry.ContractType.Pool,
                ExceptionsLibrary.NOT_POOL
            );

            // Check that sender is pool owner
            require(
                msg.sender == pool.owner(),
                ExceptionsLibrary.NOT_POOL_OWNER
            );

            // Check that pool is not active yet
            require(!pool.isDAO(), ExceptionsLibrary.IS_DAO);
        }

        // Create token contract
        IToken token = _createToken();

        // Create TGE contract
        ITGE tge = _createTGE(metadataURI, address(pool));

        // Initialize token
        token.initialize(
            address(pool),
            IToken.TokenInfo({
                tokenType: IToken.TokenType.Governance,
                name: "",
                symbol: tokenSymbol,
                description: "",
                cap: tokenCap,
                decimals: 18
            }),
            address(tge)
        );

        // Set token as pool token
        pool.setToken(address(token), IToken.TokenType.Governance);

        // Initialize TGE
        tge.initialize(token, tgeInfo, protocolTokenFee);

        // Emit event
        emit PoolCreated(address(pool), address(token), address(tge));
    }

    // PUBLIC INDIRECT FUNCTIONS (CALLED THROUGH POOL)

    /**
     * @dev Method for launching secondary TGE (i.e. without reissuing the token) for Governance tokens, as well as for creating and launching TGE for Preference tokens. It can be started only as a result of the execution of the proposal on behalf of the pool.
     * @param tgeInfo TGE parameters
     * @param tokenInfo Token parameters
     * @param metadataURI Metadata URI
     */
    function createSecondaryTGE(
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external override onlyPool nonReentrant whenNotPaused {
        // Create TGE
        ITGE tge = _createTGE(metadataURI, msg.sender);

        // Get token contract
        IToken token = IPool(msg.sender).getToken(tokenInfo.tokenType);

        // Check for token type (Governance or Preference)
        if (tokenInfo.tokenType == IToken.TokenType.Governance) {
            // Case of Governance token

            // Check that there is no active TGE
            require(
                ITGE(token.lastTGE()).state() != ITGE.State.Active,
                ExceptionsLibrary.ACTIVE_TGE_EXISTS
            );

            // Add TGE to token's list
            token.addTGE(address(tge));

            // Initialize TGE
            tge.initialize(token, tgeInfo, protocolTokenFee);
        } else if (tokenInfo.tokenType == IToken.TokenType.Preference) {
            // Case of Preference token

            // Check if it's new token or additional TGE
            if (
                address(token) == address(0) ||
                ITGE(token.getTGEList()[0]).state() == ITGE.State.Failed
            ) {
                // Create token contract
                token = _createToken();

                // Initialize token contract
                token.initialize(msg.sender, tokenInfo, address(tge));

                // Add token to Pool
                IPool(msg.sender).setToken(
                    address(token),
                    IToken.TokenType.Preference
                );

                // Initialize TGE
                tge.initialize(token, tgeInfo, 0);
            } else {
                // Check that there is no active TGE
                require(
                    ITGE(token.lastTGE()).state() != ITGE.State.Active,
                    ExceptionsLibrary.ACTIVE_TGE_EXISTS
                );

                // Add TGE to token's list
                token.addTGE(address(tge));

                // Initialize TGE
                tge.initialize(token, tgeInfo, 0);
            }
        } else {
            // Revert for unsupported token types
            revert(ExceptionsLibrary.UNSUPPORTED_TOKEN_TYPE);
        }

        // Emit event
        emit SecondaryTGECreated(msg.sender, address(tge), address(token));
    }

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

    // RESTRICTED FUNCTIONS

    /**
     * @dev Transfer collected createPool protocol fees
     * @param to Transfer recipient
     */
    function transferCollectedFees(address to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(to != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        uint256 balance = payable(address(this)).balance;
        (bool success, ) = payable(to).call{value: balance}("");
        require(success, ExceptionsLibrary.EXECUTION_FAILED);
        emit FeesTransferred(to, balance);
    }

    /**
     * @dev Assignment of the address to which the commission will be collected in the form of Governance tokens issued under successful TGE
     * @param _protocolTreasury Protocol treasury address
     */
    function setProtocolTreasury(address _protocolTreasury)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
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
    function setProtocolTokenFee(uint256 _protocolTokenFee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_protocolTokenFee <= DENOM, ExceptionsLibrary.INVALID_VALUE);

        protocolTokenFee = _protocolTokenFee;
        emit ProtocolTokenFeeChanged(_protocolTokenFee);
    }

    /**
     * @dev Cancel pool's proposal
     * @param pool pool
     * @param proposalId proposalId
     */
    function cancelProposal(address pool, uint256 proposalId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
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
                IPool(_pool).getToken(IToken.TokenType.Governance).cap() -
                getProtocolTokenFee(
                    IPool(_pool).getToken(IToken.TokenType.Governance).cap()
                );
        }

        return type(uint256).max - getProtocolTokenFee(type(uint256).max);
    }

    /// @dev Service function that is used to check the correctness of TGE parameters (for the absence of conflicts between parameters)
    function validateTGEInfo(
        ITGE.TGEInfo calldata info,
        uint256 cap,
        uint256 totalSupply,
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

        // Check remaining supply
        uint256 remainingSupply = cap - totalSupply;
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
    function getPoolAddress(IRegistry.CompanyInfo memory info)
        external
        view
        returns (address)
    {
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
    function _getCreate2Data(IRegistry.CompanyInfo memory info)
        internal
        view
        returns (bytes32 salt, bytes memory deployBytecode)
    {
        // Get salt
        salt = keccak256(
            abi.encode(info.jurisdiction, info.entityType, info.ein)
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
    function _createPool(IRegistry.CompanyInfo memory info)
        internal
        returns (IPool pool)
    {
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

    /**
     * @dev Create token contract
     * @return token Token contract
     */
    function _createToken() internal returns (IToken token) {
        // Create token contract
        token = IToken(address(new BeaconProxy(tokenBeacon, "")));

        // Add token contract to registry
        registry.addContractRecord(
            address(token),
            IRecordsRegistry.ContractType.GovernanceToken,
            ""
        );
    }

    /**
     * @dev Create TGE contract
     * @param metadataURI TGE metadata URI
     * @param pool Pool address
     * @return tge TGE contract
     */
    function _createTGE(string memory metadataURI, address pool)
        internal
        returns (ITGE tge)
    {
        // Create TGE contract
        tge = ITGE(address(new BeaconProxy(tgeBeacon, "")));

        // Add TGE contract to registry
        registry.addContractRecord(
            address(tge),
            IRecordsRegistry.ContractType.TGE,
            metadataURI
        );

        // Add TGE event to registry
        registry.addEventRecord(
            pool,
            IRecordsRegistry.EventType.TGE,
            address(tge),
            0,
            ""
        );
    }
}