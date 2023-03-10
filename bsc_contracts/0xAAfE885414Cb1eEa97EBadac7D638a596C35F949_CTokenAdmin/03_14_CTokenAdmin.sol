pragma solidity ^0.5.16;

import "./CErc20.sol";
import "./CToken.sol";
import "./EIP20NonStandardInterface.sol";

contract CTokenAdmin is Exponential {
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
    event SetReserveManager(address indexed oldReserveManager, address indexed newAdmin);

    /// @notice Emits when a new cToken pending admin is queued
    event PendingAdminQueued(address indexed cToken, address indexed newPendingAdmin, uint256 expiration);

    /// @notice Emits when a new cToken pending admin is cleared
    event PendingAdminCleared(address indexed cToken, address indexed newPendingAdmin);

    /// @notice Emits when a new cToken pending admin becomes active
    event PendingAdminChanged(address indexed cToken, address indexed newPendingAdmin);

    /// @notice Emits when a new cToken implementation is queued
    event ImplementationQueued(address indexed cToken, address indexed newImplementation, uint256 expiration);

    /// @notice Emits when a new cToken implementation is cleared
    event ImplementationCleared(address indexed cToken, address indexed newImplementation);

    /// @notice Emits when a new cToken implementation becomes active
    event ImplementationChanged(address indexed cToken, address indexed newImplementation);

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
        require(msg.sender == reserveManager, "only the reserve manager may call this function");
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
     * @notice Get cToken admin
     * @param cToken The cToken address
     */
    function getCTokenAdmin(address cToken) public view returns (address) {
        return CToken(cToken).admin();
    }

    /**
     * @notice Queue cToken pending admin
     * @param cToken The cToken address
     * @param newPendingAdmin The new pending admin
     */
    function _queuePendingAdmin(address cToken, address payable newPendingAdmin) external onlyAdmin {
        require(cToken != address(0) && newPendingAdmin != address(0), "invalid input");
        require(adminQueue[cToken][newPendingAdmin] == 0, "already in queue");
        uint256 expiration = add_(getBlockTimestamp(), timeLock);
        adminQueue[cToken][newPendingAdmin] = expiration;

        emit PendingAdminQueued(cToken, newPendingAdmin, expiration);
    }

    /**
     * @notice Clear cToken pending admin
     * @param cToken The cToken address
     * @param newPendingAdmin The new pending admin
     */
    function _clearPendingAdmin(address cToken, address payable newPendingAdmin) external onlyAdmin {
        adminQueue[cToken][newPendingAdmin] = 0;

        emit PendingAdminCleared(cToken, newPendingAdmin);
    }

    /**
     * @notice Toggle cToken pending admin
     * @param cToken The cToken address
     * @param newPendingAdmin The new pending admin
     */
    function _togglePendingAdmin(address cToken, address payable newPendingAdmin) external onlyAdmin returns (uint256) {
        uint256 result = adminQueue[cToken][newPendingAdmin];
        require(result != 0, "not in queue");
        require(result <= getBlockTimestamp(), "queue not expired");

        adminQueue[cToken][newPendingAdmin] = 0;

        emit PendingAdminChanged(cToken, newPendingAdmin);

        return CTokenInterface(cToken)._setPendingAdmin(newPendingAdmin);
    }

    /**
     * @notice Accept cToken admin
     * @param cToken The cToken address
     */
    function _acceptAdmin(address cToken) external onlyAdmin returns (uint256) {
        return CTokenInterface(cToken)._acceptAdmin();
    }

    /**
     * @notice Set cToken comptroller
     * @param cToken The cToken address
     * @param newComptroller The new comptroller address
     */
    function _setComptroller(address cToken, ComptrollerInterface newComptroller) external onlyAdmin returns (uint256) {
        return CTokenInterface(cToken)._setComptroller(newComptroller);
    }

    /**
     * @notice Set cToken reserve factor
     * @param cToken The cToken address
     * @param newReserveFactorMantissa The new reserve factor
     */
    function _setReserveFactor(address cToken, uint256 newReserveFactorMantissa) external onlyAdmin returns (uint256) {
        return CTokenInterface(cToken)._setReserveFactor(newReserveFactorMantissa);
    }

    /**
     * @notice Reduce cToken reserve
     * @param cToken The cToken address
     * @param reduceAmount The amount of reduction
     */
    function _reduceReserves(address cToken, uint256 reduceAmount) external onlyAdmin returns (uint256) {
        return CTokenInterface(cToken)._reduceReserves(reduceAmount);
    }

    /**
     * @notice Set cToken IRM
     * @param cToken The cToken address
     * @param newInterestRateModel The new IRM address
     */
    function _setInterestRateModel(address cToken, InterestRateModel newInterestRateModel)
        external
        onlyAdmin
        returns (uint256)
    {
        return CTokenInterface(cToken)._setInterestRateModel(newInterestRateModel);
    }

    /**
     * @notice Set cToken collateral cap
     * @dev It will revert if the cToken is not CCollateralCap.
     * @param cToken The cToken address
     * @param newCollateralCap The new collateral cap
     */
    function _setCollateralCap(address cToken, uint256 newCollateralCap) external onlyAdmin {
        CCollateralCapErc20Interface(cToken)._setCollateralCap(newCollateralCap);
    }

    /**
     * @notice Queue cToken pending implementation
     * @param cToken The cToken address
     * @param implementation The new pending implementation
     */
    function _queuePendingImplementation(address cToken, address implementation) external onlyAdmin {
        require(cToken != address(0) && implementation != address(0), "invalid input");
        require(implementationQueue[cToken][implementation] == 0, "already in queue");
        uint256 expiration = add_(getBlockTimestamp(), timeLock);
        implementationQueue[cToken][implementation] = expiration;

        emit ImplementationQueued(cToken, implementation, expiration);
    }

    /**
     * @notice Clear cToken pending implementation
     * @param cToken The cToken address
     * @param implementation The new pending implementation
     */
    function _clearPendingImplementation(address cToken, address implementation) external onlyAdmin {
        implementationQueue[cToken][implementation] = 0;

        emit ImplementationCleared(cToken, implementation);
    }

    /**
     * @notice Toggle cToken pending implementation
     * @param cToken The cToken address
     * @param implementation The new pending implementation
     * @param allowResign Allow old implementation to resign or not
     * @param becomeImplementationData The payload data
     */
    function _togglePendingImplementation(
        address cToken,
        address implementation,
        bool allowResign,
        bytes calldata becomeImplementationData
    ) external onlyAdmin {
        uint256 result = implementationQueue[cToken][implementation];
        require(result != 0, "not in queue");
        require(result <= getBlockTimestamp(), "queue not expired");

        implementationQueue[cToken][implementation] = 0;

        emit ImplementationChanged(cToken, implementation);

        CDelegatorInterface(cToken)._setImplementation(implementation, allowResign, becomeImplementationData);
    }

    /**
     * @notice Extract reserves by the reserve manager
     * @param cToken The cToken address
     * @param reduceAmount The amount of reduction
     */
    function extractReserves(address cToken, uint256 reduceAmount) external onlyReserveManager {
        require(CTokenInterface(cToken)._reduceReserves(reduceAmount) == 0, "failed to reduce reserves");

        address underlying = CErc20(cToken).underlying();
        _transferToken(underlying, reserveManager, reduceAmount);
    }

    /**
     * @notice Seize the stock assets
     * @param token The token address
     */
    function seize(address token) external onlyAdmin {
        uint256 amount = EIP20NonStandardInterface(token).balanceOf(address(this));
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
    function setReserveManager(address payable newReserveManager) external onlyAdmin {
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