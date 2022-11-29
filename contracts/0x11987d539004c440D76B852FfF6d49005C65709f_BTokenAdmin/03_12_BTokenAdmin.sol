pragma solidity 0.5.16;

import "./BErc20.sol";
import "./BToken.sol";
import "./EIP20NonStandardInterface.sol";

contract BTokenAdmin is Exponential {
    uint256 public constant timeLock = 2 days;

    /// @notice Admin address
    address payable public admin;

    /// @notice Reserve manager address
    address payable public reserveManager;

    /// @notice Admin queue
    mapping(address => mapping(address => uint256)) public adminQueue;

    /// @notice Implementation queue
    mapping(address => mapping(address => uint256)) public implementationQueue;

    /// @notice Emits when a new admin is assigned
    event SetAdmin(address indexed oldAdmin, address indexed newAdmin);

    /// @notice Emits when a new reserve manager is assigned
    event SetReserveManager(
        address indexed oldReserveManager,
        address indexed newAdmin
    );

    /// @notice Emits when a new bToken pending admin is queued
    event PendingAdminQueued(
        address indexed bToken,
        address indexed newPendingAdmin,
        uint256 expiration
    );

    /// @notice Emits when a new bToken pending admin is cleared
    event PendingAdminCleared(
        address indexed bToken,
        address indexed newPendingAdmin
    );

    /// @notice Emits when a new bToken pending admin becomes active
    event PendingAdminChanged(
        address indexed bToken,
        address indexed newPendingAdmin
    );

    /// @notice Emits when a new bToken implementation is queued
    event ImplementationQueued(
        address indexed bToken,
        address indexed newImplementation,
        uint256 expiration
    );

    /// @notice Emits when a new bToken implementation is cleared
    event ImplementationCleared(
        address indexed bToken,
        address indexed newImplementation
    );

    /// @notice Emits when a new bToken implementation becomes active
    event ImplementationChanged(
        address indexed bToken,
        address indexed newImplementation
    );

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "only the admin may call this function");
        _;
    }

    /**
     * @dev Throws if called by any account other than the reserve manager.
     */
    modifier onlyReserveManager() {
        require(
            msg.sender == reserveManager,
            "only the reserve manager may call this function"
        );
        _;
    }

    constructor(address payable _admin) public {
        _setAdmin(_admin);
    }

    /**
     * @notice Get block timestamp
     */
    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Get bToken admin
     * @param bToken The bToken address
     */
    function getBTokenAdmin(address bToken) public view returns (address) {
        return BToken(bToken).admin();
    }

    /**
     * @notice Queue bToken pending admin
     * @param bToken The bToken address
     * @param newPendingAdmin The new pending admin
     */
    function _queuePendingAdmin(address bToken, address payable newPendingAdmin)
        external
        onlyAdmin
    {
        require(
            bToken != address(0) && newPendingAdmin != address(0),
            "invalid input"
        );
        require(adminQueue[bToken][newPendingAdmin] == 0, "already in queue");
        uint256 expiration = add_(getBlockTimestamp(), timeLock);
        adminQueue[bToken][newPendingAdmin] = expiration;

        emit PendingAdminQueued(bToken, newPendingAdmin, expiration);
    }

    /**
     * @notice Clear bToken pending admin
     * @param bToken The bToken address
     * @param newPendingAdmin The new pending admin
     */
    function _clearPendingAdmin(address bToken, address payable newPendingAdmin)
        external
        onlyAdmin
    {
        adminQueue[bToken][newPendingAdmin] = 0;

        emit PendingAdminCleared(bToken, newPendingAdmin);
    }

    /**
     * @notice Toggle bToken pending admin
     * @param bToken The bToken address
     * @param newPendingAdmin The new pending admin
     */
    function _togglePendingAdmin(
        address bToken,
        address payable newPendingAdmin
    ) external onlyAdmin returns (uint256) {
        uint256 result = adminQueue[bToken][newPendingAdmin];
        require(result != 0, "not in queue");
        require(result <= getBlockTimestamp(), "queue not expired");

        adminQueue[bToken][newPendingAdmin] = 0;

        emit PendingAdminChanged(bToken, newPendingAdmin);

        return BTokenInterface(bToken)._setPendingAdmin(newPendingAdmin);
    }

    /**
     * @notice Accept bToken admin
     * @param bToken The bToken address
     */
    function _acceptAdmin(address bToken) external onlyAdmin returns (uint256) {
        return BTokenInterface(bToken)._acceptAdmin();
    }

    /**
     * @notice Set bToken comptroller
     * @param bToken The bToken address
     * @param newComptroller The new comptroller address
     */
    function _setComptroller(
        address bToken,
        ComptrollerInterface newComptroller
    ) external onlyAdmin returns (uint256) {
        return BTokenInterface(bToken)._setComptroller(newComptroller);
    }

    /**
     * @notice Set bToken reserve factor
     * @param bToken The bToken address
     * @param newReserveFactorMantissa The new reserve factor
     */
    function _setReserveFactor(address bToken, uint256 newReserveFactorMantissa)
        external
        onlyAdmin
        returns (uint256)
    {
        return
            BTokenInterface(bToken)._setReserveFactor(newReserveFactorMantissa);
    }

    /**
     * @notice Reduce bToken reserve
     * @param bToken The bToken address
     * @param reduceAmount The amount of reduction
     */
    function _reduceReserves(address bToken, uint256 reduceAmount)
        external
        onlyAdmin
        returns (uint256)
    {
        return BTokenInterface(bToken)._reduceReserves(reduceAmount);
    }

    /**
     * @notice Set bToken IRM
     * @param bToken The bToken address
     * @param newInterestRateModel The new IRM address
     */
    function _setInterestRateModel(
        address bToken,
        InterestRateModel newInterestRateModel
    ) external onlyAdmin returns (uint256) {
        return
            BTokenInterface(bToken)._setInterestRateModel(newInterestRateModel);
    }

    /**
     * @notice Set bToken collateral cap
     * @dev It will revert if the bToken is not BCollateralCap.
     * @param bToken The bToken address
     * @param newCollateralCap The new collateral cap
     */
    function _setCollateralCap(address bToken, uint256 newCollateralCap)
        external
        onlyAdmin
    {
        BCollateralCapErc20Interface(bToken)._setCollateralCap(
            newCollateralCap
        );
    }

    /**
     * @notice Queue bToken pending implementation
     * @param bToken The bToken address
     * @param implementation The new pending implementation
     */
    function _queuePendingImplementation(address bToken, address implementation)
        external
        onlyAdmin
    {
        require(
            bToken != address(0) && implementation != address(0),
            "invalid input"
        );
        require(
            implementationQueue[bToken][implementation] == 0,
            "already in queue"
        );
        uint256 expiration = add_(getBlockTimestamp(), timeLock);
        implementationQueue[bToken][implementation] = expiration;

        emit ImplementationQueued(bToken, implementation, expiration);
    }

    /**
     * @notice Clear bToken pending implementation
     * @param bToken The bToken address
     * @param implementation The new pending implementation
     */
    function _clearPendingImplementation(address bToken, address implementation)
        external
        onlyAdmin
    {
        implementationQueue[bToken][implementation] = 0;

        emit ImplementationCleared(bToken, implementation);
    }

    /**
     * @notice Toggle bToken pending implementation
     * @param bToken The bToken address
     * @param implementation The new pending implementation
     * @param allowResign Allow old implementation to resign or not
     * @param becomeImplementationData The payload data
     */
    function _togglePendingImplementation(
        address bToken,
        address implementation,
        bool allowResign,
        bytes calldata becomeImplementationData
    ) external onlyAdmin {
        uint256 result = implementationQueue[bToken][implementation];
        require(result != 0, "not in queue");
        require(result <= getBlockTimestamp(), "queue not expired");

        implementationQueue[bToken][implementation] = 0;

        emit ImplementationChanged(bToken, implementation);

        BDelegatorInterface(bToken)._setImplementation(
            implementation,
            allowResign,
            becomeImplementationData
        );
    }

    /**
     * @notice Extract reserves by the reserve manager
     * @param bToken The bToken address
     * @param reduceAmount The amount of reduction
     */
    function extractReserves(address bToken, uint256 reduceAmount)
        external
        onlyReserveManager
    {
        require(
            BTokenInterface(bToken)._reduceReserves(reduceAmount) == 0,
            "failed to reduce reserves"
        );

        address underlying = BErc20(bToken).underlying();
        _transferToken(underlying, reserveManager, reduceAmount);
    }

    /**
     * @notice Seize the stock assets
     * @param token The token address
     */
    function seize(address token) external onlyAdmin {
        uint256 amount = EIP20NonStandardInterface(token).balanceOf(
            address(this)
        );
        if (amount > 0) {
            _transferToken(token, admin, amount);
        }
    }

    /**
     * @notice Set the admin
     * @param newAdmin The new admin
     */
    function setAdmin(address payable newAdmin) external onlyAdmin {
        _setAdmin(newAdmin);
    }

    /**
     * @notice Set the reserve manager
     * @param newReserveManager The new reserve manager
     */
    function setReserveManager(address payable newReserveManager)
        external
        onlyAdmin
    {
        address oldReserveManager = reserveManager;
        reserveManager = newReserveManager;

        emit SetReserveManager(oldReserveManager, newReserveManager);
    }

    /* Internal functions */

    function _setAdmin(address payable newAdmin) private {
        require(newAdmin != address(0), "new admin cannot be zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit SetAdmin(oldAdmin, newAdmin);
    }

    function _transferToken(
        address token,
        address payable to,
        uint256 amount
    ) private {
        require(to != address(0), "receiver cannot be zero address");

        EIP20NonStandardInterface(token).transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                if lt(returndatasize(), 32) {
                    revert(0, 0) // This is a non-compliant ERC-20, revert.
                }
                returndatacopy(0, 0, 32) // Vyper compiler before 0.2.8 will not truncate RETURNDATASIZE.
                success := mload(0) // See here: https://github.com/vyperlang/vyper/security/advisories/GHSA-375m-5fvv-xq23
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}