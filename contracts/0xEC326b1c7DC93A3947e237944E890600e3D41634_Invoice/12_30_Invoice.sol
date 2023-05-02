// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./libraries/ExceptionsLibrary.sol";
import "./interfaces/registry/IRegistry.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IInvoice.sol";

contract Invoice is Initializable, ReentrancyGuardUpgradeable, IInvoice {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // STORAGE

    /// @notice Registry contract
    IRegistry public registry;

    /// @notice last InvoiceId For Pool
    mapping(address => uint256) public lastInvoiceIdForPool;

    /// @notice last InvoiceId For Pool
    mapping(address => mapping(uint256 => InvoiceInfo)) public invoices;

    // EVENTS

    /**
     * @dev Event emitted on invoice creating
     * @param pool Pool address
     * @param invoiceId InvoiceId for Pool
     */
    event InvoiceCreated(address pool, uint256 invoiceId);

    /**
     * @dev Event emitted when invoice is canceled
     * @param pool Pool address
     * @param invoiceId InvoiceId for Pool
     */
    event InvoiceCanceled(address pool, uint256 invoiceId);

    /**
     * @dev Event emitted when invoice is paid
     * @param pool Pool address
     * @param invoiceId InvoiceId for Pool
     */
    event InvoicePaid(address pool, uint256 invoiceId);

    // MODIFIERS
    modifier onlyValidInvoiceManager(address pool) {
        require(
            isValidInvoiceManager(pool, msg.sender),
            ExceptionsLibrary.NOT_INVOICE_MANAGER
        );
        _;
    }

    modifier onlyManager() {
        require(
            registry.service().hasRole(
                registry.service().SERVICE_MANAGER_ROLE(),
                msg.sender
            ),
            ExceptionsLibrary.INVALID_USER
        );
        _;
    }

    modifier whenPoolNotPaused(address pool) {
        require(!IPool(pool).paused(), ExceptionsLibrary.POOL_PAUSED);
        _;
    }

    modifier onlyActive(address pool, uint256 invoiceId) {
        require(
            invoiceState(pool, invoiceId) == InvoiceState.Active,
            ExceptionsLibrary.WRONG_STATE
        );
        _;
    }

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract initializer
     * @param registry_ Protocol registry address
     */
    function initialize(IRegistry registry_) external initializer {
        registry = registry_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @notice Pay Invoice
     * @param pool Pool address
     * @param invoiceId InvoiceId
     */
    function payInvoice(
        address pool,
        uint256 invoiceId
    ) external payable nonReentrant whenPoolNotPaused(pool) {
        InvoiceInfo memory invoice = invoices[pool][invoiceId];

        require(
            invoiceState(pool, invoiceId) == InvoiceState.Active,
            ExceptionsLibrary.WRONG_STATE
        );

        //check if payer is whitelisted
        if (invoice.core.whitelist.length > 0) {
            bool isWhitelisted = false;
            for (uint256 i = 0; i < invoice.core.whitelist.length; i++) {
                if (invoice.core.whitelist[i] == msg.sender)
                    isWhitelisted = true;
            }
            require(isWhitelisted, ExceptionsLibrary.NOT_WHITELISTED);
        }

        //if unitOfAccount is ETH
        if (invoice.core.unitOfAccount == address(0)) {
            require(
                msg.value == invoice.core.amount,
                ExceptionsLibrary.WRONG_AMOUNT
            );

            (bool success, ) = payable(pool).call{value: invoice.core.amount}(
                ""
            );
            require(success, ExceptionsLibrary.WRONG_AMOUNT);
        } else {
            IERC20Upgradeable(invoice.core.unitOfAccount).safeTransferFrom(
                msg.sender,
                pool,
                invoice.core.amount
            );
        }

        _setInvoicePaid(pool, invoiceId);
    }

    /**
     * @notice create Invoice for given pool (only PoolSecretary)
     * @param pool Pool address
     * @param core InvoiceCore
     */
    function createInvoice(
        address pool,
        InvoiceCore memory core
    ) external onlyValidInvoiceManager(pool) {
        //check if pool registry record exists
        require(
            registry.typeOf(pool) == IRecordsRegistry.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );

        //validation
        validateInvoiceCore(core);

        InvoiceInfo memory info;
        info.core = core;
        info.createdBy = msg.sender;

        //set invoiceId
        uint256 invoiceId = lastInvoiceIdForPool[pool];
        info.invoiceId = invoiceId;

        //add invoice
        invoices[pool][invoiceId] = info;
        lastInvoiceIdForPool[pool]++;

        emit InvoiceCreated(pool, invoiceId);
    }

    /**
     * @notice Cancel Invoice by invoice id (only PoolSecretary)
     * @param pool Pool address
     * @param invoiceId invoiceId
     */
    function cancelInvoice(
        address pool,
        uint256 invoiceId
    ) external onlyValidInvoiceManager(pool) {
        _setInvoiceCanceled(pool, invoiceId);
    }

    /**
     * @notice Set invoice paid for manual confirmation of payment
     * @param pool Pool address
     * @param invoiceId invoiceId
     */
    function setInvoicePaid(
        address pool,
        uint256 invoiceId
    ) external onlyManager {
        _setInvoicePaid(pool, invoiceId);
    }

    /**
     * @notice Set invoice paid for manual invoice cancellation
     * @param pool Pool address
     * @param invoiceId invoiceId
     */
    function setInvoiceCanceled(
        address pool,
        uint256 invoiceId
    ) external onlyManager {
        _setInvoiceCanceled(pool, invoiceId);
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @notice Validates invoice params
     * @param core Invoice params
     * @return True if params are valid (reverts otherwise)
     */
    function validateInvoiceCore(
        InvoiceCore memory core
    ) public view returns (bool) {
        require(core.amount > 0, ExceptionsLibrary.WRONG_AMOUNT);

        require(
            core.expirationBlock > block.number,
            ExceptionsLibrary.WRONG_BLOCK_NUMBER
        );

        require(
            core.unitOfAccount == address(0) ||
                IERC20Upgradeable(core.unitOfAccount).totalSupply() > 0,
            ExceptionsLibrary.WRONG_TOKEN_ADDRESS
        );
        return true;
    }

    /**
     * @dev This method returns invoice state
     * @param invoiceId Invoice ID
     * @return Invoice State
     */
    function invoiceState(
        address pool,
        uint256 invoiceId
    ) public view returns (InvoiceState) {
        InvoiceInfo memory invoice = invoices[pool][invoiceId];

        if (invoice.isPaid) return InvoiceState.Paid;

        if (invoice.isCanceled) return InvoiceState.Canceled;

        if (invoice.core.expirationBlock < block.number)
            return InvoiceState.Expired;

        return InvoiceState.Active;
    }

    /// @dev This getter check if address is Valid Invoice Manager
    function isValidInvoiceManager(
        address pool,
        address account
    ) public view returns (bool) {
        if (
            IPool(pool).isPoolSecretary(account) ||
            registry.service().hasRole(
                registry.service().SERVICE_MANAGER_ROLE(),
                account
            )
        ) return true;
        if (!IPool(pool).isDAO() && account == IPool(pool).owner()) return true;
        return false;
    }

    //PRIVATE

    function _setInvoicePaid(
        address pool,
        uint256 invoiceId
    ) private onlyActive(pool, invoiceId) {
        invoices[pool][invoiceId].isPaid = true;
        emit InvoicePaid(pool, invoiceId);
    }

    function _setInvoiceCanceled(
        address pool,
        uint256 invoiceId
    ) private onlyActive(pool, invoiceId) {
        invoices[pool][invoiceId].isCanceled = true;
        emit InvoiceCanceled(pool, invoiceId);
    }
}