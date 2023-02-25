// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Clones} from "openzeppelin/proxy/Clones.sol";

import {FirmBase, IMPL_INIT_NOOP_SAFE, IMPL_INIT_NOOP_ADDR} from "../bases/FirmBase.sol";
import {ISafe} from "../bases/interfaces/ISafe.sol";

import {EquityToken, ERC20, ERC20Votes} from "./EquityToken.sol";
import {ICaptableVotes} from "./interfaces/ICaptableVotes.sol";
import {BouncerChecker} from "./BouncerChecker.sol";
import {IBouncer} from "./interfaces/IBouncer.sol";
import {IAccountController} from "./controllers/AccountController.sol";

uint32 constant NO_CONVERSION_FLAG = type(uint32).max;
IAccountController constant NO_CONTROLLER = IAccountController(address(0));

/*
THE TRANSFER OF THE SECURITIES REFERENCED HEREIN IS SUBJECT TO CERTAIN TRANSFER
RESTRICTIONS SET FORTH IN THE COMPANY’S BYLAWS, WHICH MAY BE OBTAINED UPON
WRITTEN REQUEST TO THE COMPANY AT ITS DESIGNATED ELECTRONIC ADDRESS.
THE COMPANY SHALL NOT REGISTER OR OTHERWISE RECOGNIZE OR GIVE EFFECT TO ANY
PURPORTED TRANSFER OF SECURITIES THAT DOES NOT COMPLY WITH SUCH TRANSFER RESTRICTIONS.*/

/**
 * @title Captable
 * @author Firm ([email protected])
 * @notice Captable manages ownership and voting rights in a company, controlling
 * a set of equity tokens representing classes of stock
 */
contract Captable is FirmBase, BouncerChecker, ICaptableVotes {
    string public constant moduleId = "org.firm.captable";
    uint256 public constant moduleVersion = 1;

    using Clones for address;

    struct Class {
        EquityToken token;
        uint16 votingWeight;
        uint32 convertsToClassId;
        uint128 authorized;
        uint128 convertible;
        string name;
        string ticker;
        IBouncer bouncer;
        bool isFrozen;
        mapping(address => bool) isManager;
    }

    mapping(uint256 => Class) public classes;
    uint256 internal classCount;

    mapping(address => mapping(uint256 => IAccountController)) public controllers;

    string public name;

    // Above this limit, voting power getters that iterate through all tokens become
    // very expensive. See `CaptableClassLimitTest` tests for worst-case benchmarks
    uint32 internal constant CLASSES_LIMIT = 128;

    address internal immutable equityTokenImpl;

    event ClassCreated(
        uint256 indexed classId,
        EquityToken indexed token,
        string name,
        string ticker,
        uint128 authorized,
        uint32 convertsToClassId,
        uint16 votingWeight,
        IBouncer indexed bouncer
    );
    event AuthorizedChanged(uint256 indexed classId, uint128 authorized);
    event ConvertibleChanged(uint256 indexed classId, uint128 convertible);
    event ClassManagerSet(uint256 indexed classId, address indexed manager, bool isManager);
    event ClassFrozen(uint256 indexed classId);
    event BouncerChanged(uint256 indexed classId, IBouncer indexed bouncer);
    event Issued(address indexed to, uint256 indexed classId, uint256 amount, address indexed actor);
    event Converted(address indexed account, uint256 indexed fromClassId, uint256 toClassId, uint256 amount);
    event ControllerSet(address indexed account, uint256 indexed classId, IAccountController indexed controller);
    event ForcedTransfer(
        address indexed from, address indexed to, uint256 classId, uint256 amount, address actor, string reason
    );

    error ClassCreationAboveLimit();
    error UnexistentClass(uint256 classId);
    error BadInput();
    error FrozenClass(uint256 classId);
    error TransferBlocked(IBouncer bouncer, address from, address to, uint256 classId, uint256 amount);
    error ConversionBlocked(IAccountController controller, address account, uint256 classId, uint256 amount);
    error UnauthorizedNotController(uint256 classId);
    error IssuedOverAuthorized(uint256 classId);
    error ConvertibleOverAuthorized(uint256 classId);
    error UnauthorizedNotManager(uint256 classId);
    error AccountIsNonHolder(address account, uint256 classId);

    constructor() {
        initialize("", IMPL_INIT_NOOP_SAFE, IMPL_INIT_NOOP_ADDR);
        equityTokenImpl = address(new EquityToken());
    }

    function initialize(string memory name_, ISafe safe_, address trustedForwarder_) public {
        // calls SafeAware.__init_setSafe which reverts on reinitialization
        __init_firmBase(safe_, trustedForwarder_);
        name = name_;
    }

    /**
     * @notice Creates a new class of equity
     * @dev For gas reasons only 128 classes of equity can be created at the moment
     * @param className Name of the class (cannot be changed later)
     * @param ticker Ticker of the class (cannot be changed later)
     * @param authorized Number of shares authorized for issuance (must be > 0)
     *        It has to fit in the authorized amount of the class it converts into
     * @param convertsToClassId ID of the class that holders can convert to (NO_CONVERSION_FLAG if none)
     * @param votingWeight Voting weight of the class (will be multiplied by balance when checking votes)
     * @param bouncer Bouncer that will be used to check transfers
     *        It cannot be zero. For allow all transfers, use `EmbeddedBouncerType.AllowAll` (addrFlag=0x00..0102)
     * @return classId ID of the newly created class
     * @return token Token contract of the newly created class
     */
    function createClass(
        string calldata className,
        string calldata ticker,
        uint128 authorized,
        uint32 convertsToClassId,
        uint16 votingWeight,
        IBouncer bouncer
    ) external onlySafe returns (uint256 classId, EquityToken token) {
        if (authorized == 0 || address(bouncer) == address(0)) {
            revert BadInput();
        }
        unchecked {
            if ((classId = classCount++) >= CLASSES_LIMIT) {
                revert ClassCreationAboveLimit();
            }
        }

        // When creating the first class, unless convertsToClassId == NO_CONVERSION_FLAG,
        // this will implicitly revert, since there's no convertsToClassId for which
        // _getClass() won't revert (_getClass() is called within _changeConvertibleAmount())
        if (convertsToClassId != NO_CONVERSION_FLAG) {
            _changeConvertibleAmount(convertsToClassId, authorized, true);
        }

        // Deploys token with a non-upgradeable EIP-1967 token
        // Doesn't use create2 since the salt would just be the classId and this account's nonce is just as good
        token = EquityToken(equityTokenImpl.clone());
        token.initialize(this, uint32(classId));

        address safe = _msgSender(); // since the onlySafe modifier is used, this is the safe address
        Class storage class = classes[classId];
        class.token = token;
        class.votingWeight = votingWeight;
        class.authorized = authorized;
        class.name = className;
        class.ticker = ticker;
        class.convertsToClassId = convertsToClassId;
        class.bouncer = bouncer;
        class.isManager[safe] = true; // safe addr is set as manager for class

        emit ClassCreated(classId, token, className, ticker, authorized, convertsToClassId, votingWeight, bouncer);
        emit ClassManagerSet(classId, safe, true);
    }

    /**
     * @notice Sets the amount of authorized shares for the class
     * @dev The amount of authorized shares can only be decreased if the amount of issued shares
     *      plus the convertible amount doesn't exceed the new authorized amount
     * @param classId ID of the class
     * @param newAuthorized New authorized amount
     */
    function setAuthorized(uint256 classId, uint128 newAuthorized) external onlySafe {
        if (newAuthorized == 0) {
            revert BadInput();
        }

        Class storage class = _getClass(classId);
        _ensureClassNotFrozen(class, classId);

        uint128 oldAuthorized = class.authorized;
        bool isDecreasing = newAuthorized < oldAuthorized;

        // When decreasing the authorized amount, make sure that the issued amount
        // plus the convertible amount doesn't exceed the new authorized amount
        if (isDecreasing) {
            if (_issuedFor(class) + class.convertible > newAuthorized) {
                revert IssuedOverAuthorized(classId);
            }
        }

        // If the class converts into another class, update the convertible amount of that class
        if (class.convertsToClassId != NO_CONVERSION_FLAG) {
            uint128 delta = isDecreasing ? oldAuthorized - newAuthorized : newAuthorized - oldAuthorized;
            _changeConvertibleAmount(class.convertsToClassId, delta, !isDecreasing);
        }

        class.authorized = newAuthorized;

        emit AuthorizedChanged(classId, newAuthorized);
    }

    function _changeConvertibleAmount(uint256 classId, uint128 amount, bool isIncrease) internal {
        Class storage class = _getClass(classId);
        uint128 newConvertible = isIncrease ? class.convertible + amount : class.convertible - amount;

        // Ensure that there's enough authorized space for the new convertible if we are increasing
        if (isIncrease && _issuedFor(class) + newConvertible > class.authorized) {
            revert ConvertibleOverAuthorized(classId);
        }

        class.convertible = newConvertible;

        emit ConvertibleChanged(classId, newConvertible);
    }

    /**
     * @notice Set bouncer to control transfers of class of shares
     * @dev Freezing the class will remove the ability to ever change the bouncer again
     * @param classId ID of the class
     * @param bouncer Bouncer that will be used to check transfers
     *        It cannot be zero. For allow all transfers, use `EmbeddedBouncerType.AllowAll` (addrFlag=0x00..0102)
     */
    function setBouncer(uint256 classId, IBouncer bouncer) external onlySafe {
        if (address(bouncer) == address(0)) {
            revert BadInput();
        }

        Class storage class = _getClass(classId);

        _ensureClassNotFrozen(class, classId);

        class.bouncer = bouncer;

        emit BouncerChanged(classId, bouncer);
    }

    /**
     * @notice Sets whether an address can manage a class of shares (issue and control holder accounts)
     * @dev Warning: managers can set controllers for accounts, which can be used to transfer shares or remove controllers (e.g. vesting)
     * @dev Freezing the class will remove the ability to ever change managers, effectively freezing the set
     *      of accounts that can issue for the class or set controllers
     * @param classId ID of the class
     * @param manager Address of the manager
     * @param isManager Whether the address is set as a manager
     */
    function setManager(uint256 classId, address manager, bool isManager) external onlySafe {
        Class storage class = _getClass(classId);

        _ensureClassNotFrozen(class, classId);

        class.isManager[manager] = isManager;

        emit ClassManagerSet(classId, manager, isManager);
    }

    /**
     * @notice Freeze class of shares, preventing further changes to authorized amount, managers or bouncers
     * @dev Freezing the class is a non-reversible operation
     * @param classId ID of the class
     */
    function freeze(uint256 classId) external onlySafe {
        Class storage class = _getClass(classId);

        _ensureClassNotFrozen(class, classId);

        class.isFrozen = true;

        emit ClassFrozen(classId);
    }

    function _ensureClassNotFrozen(Class storage class, uint256 classId) internal view {
        if (class.isFrozen) {
            revert FrozenClass(classId);
        }
    }

    function _ensureSenderIsManager(Class storage class, uint256 classId) internal view {
        if (!class.isManager[_msgSender()]) {
            revert UnauthorizedNotManager(classId);
        }
    }

    /**
     * @notice Issue shares for an account
     * @dev Can be done by any manager of the class
     * @param account Address of the account to issue shares for
     * @param classId ID of the class
     * @param amount Amount of shares to issue
     */
    function issue(address account, uint256 classId, uint256 amount) public {
        if (amount == 0) {
            revert BadInput();
        }

        Class storage class = _getClass(classId);
        _ensureSenderIsManager(class, classId);

        if (_issuedFor(class) + class.convertible + amount > class.authorized) {
            revert IssuedOverAuthorized(classId);
        }

        class.token.mint(account, amount);

        emit Issued(account, classId, amount, _msgSender());
    }

    /**
     * @notice Issue shares for an account and set controller over these shares
     * @dev Can be done by any manager of the class
     * @param account Address of the account to issue shares for
     * @param classId ID of the class
     * @param amount Amount of shares to issue
     * @param controller Controller to set for the account in this class
     * @param controllerParams Parameters to pass to the controller on initialization
     */
    function issueAndSetController(
        address account,
        uint256 classId,
        uint256 amount,
        IAccountController controller,
        bytes calldata controllerParams
    ) external {
        // `issue` verifies that the class exists and sender is manager on classId
        issue(account, classId, amount);
        _setController(account, classId, amount, controller, controllerParams);
    }

    /**
     * @notice Set controller over shares for an account in a class
     * @dev Can be done by any manager of the class
     * @param account Address of the account to set controller for
     * @param classId ID of the class
     * @param controller Controller to set for the account in this class
     * @param controllerParams Parameters to pass to the controller on initialization
     */
    function setController(
        address account,
        uint256 classId,
        IAccountController controller,
        bytes calldata controllerParams
    ) external {
        Class storage class = _getClass(classId);
        _ensureSenderIsManager(class, classId);

        uint256 classBalance = class.token.balanceOf(account);
        if (classBalance == 0) {
            revert AccountIsNonHolder(account, classId);
        }
        
        _setController(account, classId, classBalance, controller, controllerParams);
    }

    /**
     * @dev This function assumes that the caller has already checked that the sender is a manager
     * and that the balance in the class for the account is non-zero
     */
    function _setController(
        address account,
        uint256 classId,
        uint256 amount,
        IAccountController controller,
        bytes calldata controllerParams
    ) internal {
        controllers[account][classId] = controller;
        controller.addAccount(account, classId, amount, controllerParams);

        emit ControllerSet(account, classId, controller);
    }

    /**
     * @notice Function called by the controller to remove itself as controller when it is no longer in use
     * @dev Can be done by the controller, likely can be triggered by the user in the controller
     * @param account Address of the account to remove controller for
     * @param classId ID of the class
     */
    function controllerDettach(address account, uint256 classId) external {
        // If it was no longer the controller for the account, consider this
        // a no-op, as it might have been the controller in the past and
        // removed by a class manager (controller had no way to know it was removed)
        if (msg.sender == address(controllers[account][classId])) {
            controllers[account][classId] = NO_CONTROLLER;
            emit ControllerSet(account, classId, NO_CONTROLLER);
        }
    }

    /**
     * @notice Forcibly transfer shares from one account to another
     * @dev Can be done by the controller of an account
     * @param account Address of the account to transfer shares from
     * @param to Address of the account to transfer shares to
     * @param classId ID of the class
     * @param amount Amount of shares to transfer
     * @param reason Reason for the transfer
     */
    function controllerForcedTransfer(
        address account,
        address to,
        uint256 classId,
        uint256 amount,
        string calldata reason
    ) external {
        // Controllers use msg.sender directly as they should be contracts that
        // call this one and should never be using metatxs
        if (msg.sender != address(controllers[account][classId])) {
            revert UnauthorizedNotController(classId);
        }

        _getClass(classId).token.forcedTransfer(account, to, amount);

        emit ForcedTransfer(account, to, classId, amount, msg.sender, reason);
    }

    /**
     * @notice Forcibly transfer shares from one account to another
     * @dev Can be done by any manager of the class (likely used to bypass the bouncer with authorization of the manager)
     * @param account Address of the account to transfer shares from
     * @param to Address of the account to transfer shares to
     * @param classId ID of the class
     * @param amount Amount of shares to transfer
     * @param reason Reason for the transfer
     */
    function managerForcedTransfer(address account, address to, uint256 classId, uint256 amount, string calldata reason)
        external
    {
        Class storage class = _getClass(classId);

        _ensureSenderIsManager(class, classId);

        class.token.forcedTransfer(account, to, amount);

        emit ForcedTransfer(account, to, classId, amount, _msgSender(), reason);
    }

    /**
     * @notice Convert shares from one class to another
     * @dev Can only be triggered voluntarely by the owner of the shares and can be blocked by the class bouncer
     * @param fromClassId ID of the class to convert from
     * @param amount Amount of shares to convert
     */
    function convert(uint256 fromClassId, uint256 amount) external {
        Class storage fromClass = _getClass(fromClassId);
        uint256 toClassId = fromClass.convertsToClassId;
        Class storage toClass = _getClass(toClassId);

        address sender = _msgSender();

        // if user has a controller for the origin class id, ensure controller allows the transfer
        IAccountController controller = controllers[sender][fromClassId];
        if (controller != NO_CONTROLLER) {
            if (!controller.isTransferAllowed(sender, sender, fromClassId, amount)) {
                revert ConversionBlocked(controller, sender, fromClassId, amount);
            }
        }

        // Class conversions cannot be blocked by class bouncer, as token
        // ownership doesn't change (always goes from sender to sender)

        fromClass.authorized -= uint128(amount);
        toClass.convertible -= uint128(amount);

        fromClass.token.burn(sender, amount);
        toClass.token.mint(sender, amount);

        emit Converted(sender, fromClassId, toClassId, amount);
    }

    /**
     * @notice Function called by EquityToken to check whether a transfer can go through
     * @param from Address of the account transferring shares
     * @param to Address of the account receiving shares
     * @param classId ID of the class
     * @param amount Amount of shares to transfer
     */
    function ensureTransferIsAllowed(address from, address to, uint256 classId, uint256 amount) external view {
        Class storage class = _getClass(classId);

        // First, ensure the class bouncer allows the transfer
        if (!bouncerAllowsTransfer(class.bouncer, from, to, classId, amount)) {
            revert TransferBlocked(class.bouncer, from, to, classId, amount);
        }

        // Then, if the holder has a controller for their shares in this class, check that
        // it allows the transfer
        IAccountController controller = controllers[from][classId];
        // from has a controller for this class id
        if (address(controller) != address(0)) {
            if (!controller.isTransferAllowed(from, to, classId, amount)) {
                revert TransferBlocked(controller, from, to, classId, amount);
            }
        }
    }

    function numberOfClasses() public view override returns (uint256) {
        return classCount;
    }

    function authorizedFor(uint256 classId) external view returns (uint256) {
        return _getClass(classId).authorized;
    }

    function issuedFor(uint256 classId) external view returns (uint256) {
        return _issuedFor(_getClass(classId));
    }

    function _issuedFor(Class storage class) internal view returns (uint256) {
        return class.token.totalSupply();
    }

    function balanceOf(address account, uint256 classId) public view override returns (uint256) {
        return _getClass(classId).token.balanceOf(account);
    }

    function getVotes(address account) external view returns (uint256 totalVotes) {
        return _weightedSumAllClasses(abi.encodeCall(ERC20Votes.getVotes, (account)));
    }

    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256) {
        return _weightedSumAllClasses(abi.encodeCall(ERC20Votes.getPastVotes, (account, blockNumber)));
    }

    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256) {
        return _weightedSumAllClasses(abi.encodeCall(ERC20Votes.getPastTotalSupply, (blockNumber)));
    }

    function getTotalVotes() external view returns (uint256) {
        return _weightedSumAllClasses(abi.encodeCall(ERC20.totalSupply, ()));
    }

    function _weightedSumAllClasses(bytes memory data) internal view returns (uint256 total) {
        uint256 n = classCount;
        for (uint256 i = 0; i < n;) {
            Class storage class = classes[i];
            uint256 votingWeight = class.votingWeight;
            if (votingWeight > 0) {
                (bool ok, bytes memory returnData) = address(class.token).staticcall(data);
                require(ok && returnData.length == 32);
                total += votingWeight * abi.decode(returnData, (uint256));
            }
            unchecked {
                i++;
            }
        }
    }

    function nameFor(uint256 classId) public view returns (string memory) {
        return string(abi.encodePacked(name, bytes(" "), _getClass(classId).name));
    }

    function tickerFor(uint256 classId) public view returns (string memory) {
        return _getClass(classId).ticker;
    }

    function _getClass(uint256 classId) internal view returns (Class storage class) {
        class = classes[classId];

        if (address(class.token) == address(0)) {
            revert UnexistentClass(classId);
        }
    }
}