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
import "./utils/CustomContext.sol";
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

/**
 * @title Service Contract
 * @notice The main contract of the protocol, the starting point of interaction for new clients.
 * @dev This contract deploys the core OZ Access Control model, where the distribution of accounts determines the behavior of most modifiers.
 * @dev The address of this contract is specified in all other contracts, and this contract also stores the addresses of those contracts. The mutual references between contracts implement a system of "own-foreign" recognition.
 * @dev This contract is responsible for updating itself and all other protocol contracts, including user contracts.
 */
contract Service is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IService,
    ERC2771Context
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    // CONSTANTS

    /** 
    * @notice Denominator for shares (such as thresholds)
    * @dev The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account.
    */
    uint256 private constant DENOM = 100 * 10 ** 4;

    /**
    * @notice Hash code of the ADMIN role for the OZ Access Control model
    * @dev The main role of the entire ecosystem, the protocol owner. The address assigned to this role can perform all actions related to updating contract implementations or interacting with or configuring the protocol's Treasury. The administrator can cancel suspicious proposals awaiting execution, pause the operation of protocol contracts and pools. In addition, the administrator can perform all actions provided for the SERVICE_MANAGER role.
    The holder of this role can assign the roles of ADMIN, WHITELISTED_USER, and SERVICE_MANAGER to other accounts.
    Storage, assignment, and revocation of the role are carried out using the standard methods of the AccessControl model from OpenZeppelin: grantRole, revokeRole, setRole.
    */
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    /**
    * @notice Hash code of the MANAGER role for the OZ Access Control model
    * @dev The administrator can delegate some of their powers to the owners of addresses assigned the SERVICE_MANAGER role. The administrator can also perform all the methods listed below. This role is assigned and removed by the administrator and was created for assigning addresses managed by worker scripts (automatic backend modules whose task is to constantly track changes in the states of all ecosystem components and initiate transactions that make actual changes and involve necessary scenarios for certain contracts at the moment).
    In addition, the holder of this role has the same powers as the holders of the Secretary and Executor roles in any pool, assigned by its shareholders.
    The holder of this role can assign the WHITELISTED_USER role to other accounts.
    Storage, assignment, and revocation of the role are carried out using the standard methods of the AccessControl model from OpenZeppelin: grantRole, revokeRole, setRole.
    */
    bytes32 public constant SERVICE_MANAGER_ROLE = keccak256("USER_MANAGER");

    /// @notice Legacy hash code of users added to the whitelist. Currently unused role.
    bytes32 public constant WHITELISTED_USER_ROLE =
        keccak256("WHITELISTED_USER");

    /// @notice Hash code of the EXECUTOR role for the OZ Access Control model
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR");

    // STORAGE

    /// @dev Address of the Registry contract
    IRegistry public registry;

    /// @dev Address of the Pool beacon contract
    address public poolBeacon;

    /// @dev Address of the Token beacon contract
    address public tokenBeacon;

    /// @dev Address of the TGE beacon contract
    address public tgeBeacon;

    /// @notice Address to hold the commission from TGE in distributed tokens
    /// @dev 0.1% (can be changed by the admin) of all Governance tokens from successful TGE are held here
    address public protocolTreasury;

    /// @notice The fee size that the protocol charges in tokens from each successful TGE (only for Governance Tokens)
    /// @dev Protocol token fee percentage value with 4 decimals.
    /// Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000
    uint256 public protocolTokenFee;

    /// @notice Total fees collected from TGE in Governance tokens for each pool
    /// @dev Protocol token fee claimed for tokens
    mapping(address => uint256) public protolCollectedFee;

    /// @dev Address of the Proposal beacon contract
    ICustomProposal public customProposal;

    /// @dev Address of the Vesting contract
    IVesting public vesting;

    /// @dev Address of the Invoice contract
    IInvoice public invoice;

    /// @dev Address of the TokenFactory contract
    ITokenFactory public tokenFactory;

    /// @dev Address of the TGEFactory contract
    ITGEFactory public tgeFactory;

    /// @dev Address of the Token beacon contract (for ERC1155 tokens)
    address public tokenERC1155Beacon;

    address public trustedForwarder;
    // EVENTS

    /**
     * @dev Event emitted upon deployment of a pool contract (i.e., creation of a pool)
     * @param pool Address of the Pool contract
     * @param token Address of the pool's token contract (usually 0, as the pool and token contracts are deployed separately)
     * @param tge Address of the TGE contract (usually 0, as the pool and TGE contracts are deployed separately)
     */
    event PoolCreated(address pool, address token, address tge);

    /**
     * @dev Event emitted upon the purchase of a pool
     * @param pool Address of the purchased pool
     * @param token Address of the pool's token contract (usually 0, as the pool does not have any tokens at the time of purchase)
     * @param tge Address of the TGE contract (usually 0)
     */
    event PoolPurchased(address pool, address token, address tge);

    /**
     * @dev Event emitted when the balance of the Protocol Treasury changes due to transfers of pool tokens collected as protocol fees.
     * @param protocolTreasury Address of the Protocol Treasury
     */
    event ProtocolTreasuryChanged(address protocolTreasury);

    /**
     * @dev Event emitted when the protocol changes the token fee collected from pool tokens.
     * @param protocolTokenFee New protocol token fee
     */
    event ProtocolTokenFeeChanged(uint256 protocolTokenFee);

    /**
     * @dev Event emitted when the service fees are transferred to another address
     * @param to Transfer recipient
     * @param amount Amount of ETH transferred
     */
    event FeesTransferred(address to, uint256 amount);

    /**
     * @dev Event emitted when a proposal is canceled by an account with the Service Manager role
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

    /// @notice Modifier that allows the method to be called only by the Pool contract.
    modifier onlyPool() {
        require(
            registry.typeOf(msg.sender) == IRecordsRegistry.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by the TGE contract.
    modifier onlyTGE() {
        require(
            registry.typeOf(msg.sender) == IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by the Registry contract.
    modifier onlyRegistry() {
        require(
            msg.sender == address(registry),
            ExceptionsLibrary.NOT_REGISTRY
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by an account with the ADMIN role in the Registry contract.
    modifier onlyManager() {
        require(
            registry.hasRole(registry.COMPANIES_MANAGER_ROLE(), msg.sender),
            ExceptionsLibrary.INVALID_USER
        );
        _;
    }

    // INITIALIZER AND CONSTRUCTOR

    /**
     * @notice Contract constructor.
     * @dev This contract uses OpenZeppelin upgrades and has no need for a constructor function.
     * The constructor is replaced with an initializer function.
     * This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
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

    // PUBLIC FUNCTIONS

    /**
     * @notice Method for purchasing a pool by the user. Among the data submitted for input, there are jurisdiction and Entity Type
     * @dev The user refers to the Service protocol's purchasePool method, in which arguments indicate the digital jurisdiction code and the digital organizational type code of the company (as well as Governance settings provided by the NewGovernanceSettings interface, and a string record that will serve as the company's trademark). If there is at least one unoccupied and available company for purchase in the Registry contract (queue record with keys in the form of user-transmitted jurisdiction and organizational type codes), the following actions occur:
    -    reserving the company for the user (removing it from the list of available ones)
    -    debiting the commission in ETH (in fact, the company's price) from the user's balance, which is equal to the fee field in the CompanyInfo structure stored in the companies of the Registry contract
    -    making changes to the contract through an internal transaction using the setNewOwnerWithSettings method, which includes changing the company's trademark, its owner, and Governance settings.
    From this point on, the user is considered the Owner of the company.
    * @param jurisdiction Digital code of the jurisdiction.
    * @param entityType Digital code of the entity type.
    * @param trademark Company's trademark.
    * @param governanceSettings Initial Governance settings.
     */
    function purchasePool(
        uint256 jurisdiction,
        uint256 entityType,
        string memory trademark,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings
    ) external payable nonReentrant whenNotPaused {
        // Create pool

        IPool pool = IPool(
            registry.getAvailableCompanyAddress(jurisdiction, entityType)
        );

        // Check fee
        require(
            msg.value == pool.getCompanyFee(),
            ExceptionsLibrary.INCORRECT_ETH_PASSED
        );

        // setNewOwnerWithSettings to pool contract
        pool.setNewOwnerWithSettings(msg.sender, trademark, governanceSettings);
        registry.lockCompany(jurisdiction, entityType);
        // Emit event
        emit PoolPurchased(address(pool), address(0), address(0));
        registry.log(
            msg.sender,
            address(this),
            msg.value,
            abi.encodeWithSelector(
                IService.purchasePool.selector,
                jurisdiction,
                entityType,
                trademark,
                governanceSettings
            )
        );
    }

    /**
     * @notice Method for manually transferring the company to a new owner.
     * @dev This method can be used when paying for the company's cost (protocol fee) through any other means (off-chain payment).
     * @param jurisdiction Digital code of the jurisdiction.
     * @param entityType Digital code of the entity type.
     * @param trademark Company's trademark.
     * @param governanceSettings Initial Governance settings.
     */
    function transferPurchasedPoolByService(
        address newowner,
        uint256 jurisdiction,
        uint256 entityType,
        string memory trademark,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings
    ) external onlyManager nonReentrant whenNotPaused {
        // Create pool
        IPool pool = IPool(
            registry.getAvailableCompanyAddress(jurisdiction, entityType)
        );

        // setNewOwnerWithSettings to pool contract

        pool.setNewOwnerWithSettings(newowner, trademark, governanceSettings);

        // Emit event
        emit PoolPurchased(address(pool), address(0), address(0));
        registry.lockCompany(jurisdiction, entityType);
        registry.log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(
                IService.transferPurchasedPoolByService.selector,
                newowner,
                jurisdiction,
                entityType,
                trademark,
                governanceSettings
            )
        );
    }

    // PUBLIC INDIRECT FUNCTIONS (CALLED THROUGH POOL OR REGISTRY)

    /**
     * @notice Adding a new record of a proposal to the Registry.
     * @dev To ensure the security and consistency of the contract architecture, user contracts do not directly interact with the Registry.
     * @dev Due to the complexity of the role model for creating proposals, registering a new record is performed from the central contract.
     * @param proposalId Proposal ID.
     */
    function addProposal(uint256 proposalId) external onlyPool whenNotPaused {
        registry.addProposalRecord(msg.sender, proposalId);
    }

    /**
     * @notice Adding a new record of an event to the Registry.
     * @dev To ensure the security and consistency of the contract architecture, user contracts do not directly interact with the Registry.
     * @param eventType Event type.
     * @param proposalId Proposal ID.
     * @param metaHash Hash value of event metadata.
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

    function addInvoiceEvent(
        address pool,
        uint256 invoiceId
    ) external whenNotPaused returns (uint256) {
        require(
            msg.sender == address(invoice),
            ExceptionsLibrary.NOT_INVOICE_MANAGER
        );

        return
            registry.addEventRecord(
                pool,
                IRecordsRegistry.EventType.Transfer,
                msg.sender,
                invoiceId,
                ""
            );
    }

    /**
     * @notice Method for deploying a pool contract.
     * @dev When working with the Registry contract, the address that has the COMPANIES_MANAGER role in that contract can deploy the pool contract by sending a transaction with the company's legal data as an argument.
     * @param companyInfo Company info.
     */
    function createPool(
        IRegistry.CompanyInfo memory companyInfo
    ) external onlyRegistry nonReentrant whenNotPaused returns (address) {
        // Create pool
        IPool pool = _createPool(companyInfo);

        // Initialize pool contract
        pool.initialize(companyInfo);

        // Emit event
        emit PoolCreated(address(pool), address(0), address(0));
        return address(pool);
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Transfer the collected protocol fees obtained from the sale of pools to the specified address.
     * @param to The transfer recipient.
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
     * @dev Sets factories for previously deployed service
     * @param tokenFactory_ TokenFactory address
     * @param tgeFactory_ TGEFactory address
     */
    function setFactories(
        ITokenFactory tokenFactory_,
        ITGEFactory tgeFactory_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenFactory = tokenFactory_;
        tgeFactory = tgeFactory_;
    }

    /**
     * @notice Method to account for the collected protocol fees.
     * @dev This method is called after each successful Governance Token Generation Event (TGE) and increases the record of the collected Governance Tokens for this pool.
     * @param _token The address of the token contract.
     * @param _protocolTokenFee The amount of tokens collected as protocol fees.
     */
    function setProtocolCollectedFee(
        address _token,
        uint256 _protocolTokenFee
    ) public onlyTGE {
        protolCollectedFee[_token] += _protocolTokenFee;
    }

    /**
     * @dev Set a new address for the protocol treasury, where the Governance tokens collected as protocol fees will be transferred.
     * @param _protocolTreasury The new address of the protocol treasury.
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
     * @dev Set a new value for the protocol token fee percentage.
     * @param _protocolTokenFee The new protocol token fee percentage value with 4 decimals.
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
     * @dev Sets new tokenERC1155 beacon
     * @param beacon Beacon address
     */
    function setTokenERC1155Beacon(
        address beacon
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(beacon != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tokenERC1155Beacon = beacon;
    }

    function setTrustForwarder(
        address _trustedForwarder
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _trustedForwarder != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        trustedForwarder = _trustedForwarder;
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
     * @notice Cancel a proposal by the administrator.
     * @dev This method is used for emergency cancellation of any proposal by an address with the ADMIN role in this contract. It is used to prevent the execution of transactions prescribed by the proposal if there are doubts about their safety.
     * @param pool The address of the pool contract.
     * @param proposalId The ID of the proposal.
     */
    // function cancelProposal(
    //     address pool,
    //     uint256 proposalId
    // ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    //     IPool(pool).cancelProposal(proposalId);
    //     emit ProposalCancelled(pool, proposalId);
    // }

    function externalCastVote(
        address pool,
        uint256 proposalId,
        bool support
    ) external {
        
        IPool(pool).externalCastVote(_msgSender(), proposalId, support);

        registry.log(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(IPool.castVote.selector, proposalId, support)
        );
    }

    function externalTransferByOwner(
        address pool,
        address to,
        uint256 amount,
        address unitOfAccount
    ) external {
        require(
            IPool(pool).owner() == _msgSender(),
            ExceptionsLibrary.NOT_POOL_OWNER
        );
        IPool(pool).externalTransferByOwner(to, amount, unitOfAccount);
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
     * @notice This method returns the minimum soft cap accepted in the protocol.
     * @dev Due to the fact that each issuance of Governance tokens involves collecting a portion of the tokens as a fee, this calculation is used to avoid conflicts related to rounding.
     * @return The minimum soft cap.
     */
    function getMinSoftCap() public view returns (uint256) {
        if(protocolTokenFee>0){
            return (DENOM + protocolTokenFee - 1) / protocolTokenFee;
        }else{
            return protocolTokenFee;
        }
    }

    /**
     * @notice This method returns the size of the protocol fee charged for issuing Governance tokens.
     * @dev The calculation is based on DENOM and the current fee rate, allowing the fee to be calculated for any amount of tokens planned for distribution.
     * @param amount The token amount.
     * @return The size of the fee in tokens.
     */
    function getProtocolTokenFee(uint256 amount) public view returns (uint256) {
        require(amount >= getMinSoftCap(), ExceptionsLibrary.INVALID_VALUE);
        return (amount * protocolTokenFee + (DENOM - 1)) / DENOM;
    }

    /**
     * @notice This method returns the amount of Governance tokens collected as a protocol fee for each pool.
     * @param token_ The address of the token contract.
     * @return The amount of collected protocol fee.
     */
    function getProtocolCollectedFee(
        address token_
    ) external view returns (uint256) {
        return protolCollectedFee[token_];
    }

    /**
     * @notice This method returns the maximum number of Governance tokens that can be issued in all subsequent TGEs for the pool.
     * @dev Due to the protocol fee mechanism, which involves minting new token units as a protocol fee, calculating this maximum can be more complex than it seems at first glance. This method takes into account reserved and potential token units and calculates the hardcap accordingly.
     * @param _pool The address of the pool contract for which the calculation is required.
     * @return The maximum hardcap value.
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

    /// @dev This method is used for formal validation of user-defined parameters for the conducted TGE.
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

    // INTERNAL FUNCTIONS

    /**
     * @dev Intermediate calculation for the create2 algorithm
     * @param info Company info
     * @return salt Create2 salt
     * @return deployBytecode Deployed bytecode
     */
    function _getCreate2Data(
        IRegistry.CompanyInfo memory info
    ) internal view returns (bytes32 salt, bytes memory deployBytecode) {
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
     * @dev Creating and initializing a pool
     * @return pool Pool contract address
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

    function getTrustedForwarder()
        public
        view
        override(ERC2771Context, IService)
        returns (address)
    {
        return trustedForwarder;
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771Context)
        returns (address sender)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, ERC2771Context)
        returns (bytes calldata)
    {
        return super._msgData();
    }
}