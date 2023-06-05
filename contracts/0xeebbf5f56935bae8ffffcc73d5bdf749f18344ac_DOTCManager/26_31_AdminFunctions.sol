//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../interfaces/ITokenListManager.sol";
import "../interfaces/IEscrow.sol";
import "../../permissioning/interfaces/IPermissionManagerV2.sol";
import "../../token/interfaces/IXTokenWrapper.sol";

/**
 * @title AdminFunctions
 * @title Contract to set special contracts addresses, freeze escrow contract, fee amount
 * @author Swarm
 */
abstract contract AdminFunctions is Initializable, AccessControlUpgradeable {
    /**
     * @dev Emmited when the escrow address set
     */
    event EscrowAddressSet(address sender, IEscrow _address);
    /**
     * @dev Emmited when the escrow linker address set
     */
    event EscrowLinkerSet(address sender, address _dotc);
    /**
     * @dev Emmited when escrow frozen
     */
    event EscrowFreeze(address sender);
    /**
     * @dev Emmited when escrow unfrozen
     */
    event EscrowUnFreeze(address sender);
    /**
     * @dev  Emmited when the token list address set
     */
    event TokenListManagerSet(address sender, ITokenListManager _tokenListManager);
    /**
     * @dev Emmited when the permission manageraddress set
     */
    event PermissionManagerSet(address sender, IPermissionManagerV2 _permissionManager);
    /**
     * @dev Emmited when the x tokens wrapper address set
     */
    event XTokenWrapperSet(address sender, IXTokenWrapper _wrapper);
    /**
     * @dev Emmited when the fee address address set
     */
    event FeeAddressSet(address sender, address _newFeeAddress);
    /**
     * @dev Emmited when the fee amount set
     */
    event FeeAmountSet(address sender, uint256 _feeAmount);

    /**
     * @dev dOTC_Admin_ROLE hashed string
     */
    bytes32 public constant dOTC_Admin_ROLE = keccak256("dOTC_ADMIN_ROLE");
    /**
     * @dev ESCROW_MANAGER_ROLE hashed string
     */
    bytes32 public constant ESCROW_MANAGER_ROLE = keccak256("ESCROW_MANAGER_ROLE");
    /**
     * @dev PERMISSION_SETTER_ROLE hashed string
     */
    bytes32 public constant PERMISSION_SETTER_ROLE = keccak256("PERMISSION_SETTER_ROLE");
    /**
     * @dev FEE_MANAGER_ROLE hashed string
     */
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    /**
     * @dev BPSNUMBER used to standardize decimals
     */
    uint256 public constant BPSNUMBER = 10 ** 27;
    /**
     * @dev DECIMAL standard of decimals in Swarm
     */
    uint256 public constant DECIMAL = 18;
    /**
     * @dev feeAmount amount of fees
     */
    uint256 public feeAmount;

    // Private variables
    ITokenListManager internal tokenListManager;
    IPermissionManagerV2 internal permissionManager;
    IEscrow internal escrow;
    IXTokenWrapper internal wrapper;
    address internal feeAddress;

    /**
     * @dev Check if sender has dOTC_Admin_ROLE role
     */
    modifier onlyDotcAdmin() {
        require(hasRole(dOTC_Admin_ROLE, _msgSender()), "AdminFunctions: Account must have dOTC_Admin_ROLE");
        _;
    }

    /**
     * @dev Check if sender has PERMISSION_SETTER_ROLE role
     */
    modifier onlyPermissionSetter() {
        require(
            hasRole(PERMISSION_SETTER_ROLE, _msgSender()),
            "AdminFunctions: Account must have PERMISSION_SETTER_ROLE"
        );
        _;
    }

    /**
     * @dev Check if sender has FEE_MANAGER_ROLE role
     */
    modifier onlyFeeManager() {
        require(hasRole(FEE_MANAGER_ROLE, _msgSender()), "AdminFunctions: Account must have FEE_MANAGER_ROLE");
        _;
    }

    /**
     * @dev Check if sender has ESCROW_MANAGER_ROLE manager role
     */
    modifier onlyEscrowManager() {
        require(hasRole(ESCROW_MANAGER_ROLE, _msgSender()), "AdminFunctions: Only escrow manager");
        _;
    }

    /**
     * @dev Grants dOTC_Admin_ROLE to `_dOTCAdmin`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setdOTCAdmin(address _dOTCAdmin) external {
        grantRole(dOTC_Admin_ROLE, _dOTCAdmin);
    }

    /**
     * @dev Sets XTokenWrapper to `_wrapper`.
     *
     * Requirements:
     *
     * - the caller must have `dOTC_Admin_ROLE` admin role.
     */
    function setXTokenWrapper(IXTokenWrapper _wrapper) public onlyDotcAdmin returns (bool status) {
        wrapper = _wrapper;

        emit XTokenWrapperSet(msg.sender, _wrapper);

        return true;
    }

    /**
     * @dev Sets Escrow to `_escrow`.
     *
     * Requirements:
     *
     * - the caller must have `ESCROW_MANAGER_ROLE` admin role.
     */
    function setEscrowAddress(IEscrow _escrow) public onlyEscrowManager returns (bool status) {
        escrow = _escrow;

        emit EscrowAddressSet(msg.sender, _escrow);

        return true;
    }

    /**
     * @dev Sets Escrow linker to `address(this)`.
     *
     * Requirements:
     *
     * - the caller must have `ESCROW_MANAGER_ROLE` admin role.
     */
    function setEscrowLinker() external onlyEscrowManager returns (bool status) {
        require(escrow.setdOTCAddress(address(this)), "AdminFunctions: escrow linker set error");
        emit EscrowLinkerSet(msg.sender, address(this));

        return true;
    }

    /**
     * @dev Freezes Escrow.
     *
     * Requirements:
     *
     * - the caller must have `dOTC_Admin_ROLE` admin role.
     */
    function freezeEscrow() external onlyDotcAdmin returns (bool status) {
        require(escrow.freezeEscrow(msg.sender), "AdminFunctions: escrow freezing failed");
        emit EscrowFreeze(msg.sender);

        return true;
    }

    /**
     * @dev UnFreezes Escrow.
     *
     * Requirements:
     *
     * - the caller must have `dOTC_Admin_ROLE` admin role.
     */
    function unFreezeEscrow() external onlyDotcAdmin returns (bool status) {
        require(escrow.unFreezeEscrow(msg.sender), "AdminFunctions: escrow unfreezing failed");
        emit EscrowUnFreeze(msg.sender);

        return true;
    }

    /**
     * @dev Sets TokenListManager to `_tokenListManager`.
     *
     * Requirements:
     *
     * - the caller must have `dOTC_Admin_ROLE` admin role.
     */
    function setTokenListManager(ITokenListManager _tokenListManager) external onlyDotcAdmin returns (bool status) {
        tokenListManager = _tokenListManager;

        emit TokenListManagerSet(msg.sender, _tokenListManager);

        return true;
    }

    /**
     * @dev Sets PermissionManager to `_permissionManager`.
     *
     * Requirements:
     *
     * - the caller must have `PERMISSION_SETTER_ROLE` admin role.
     */
    function setPermissionManager(
        IPermissionManagerV2 _permissionManager
    ) external onlyPermissionSetter returns (bool status) {
        permissionManager = _permissionManager;

        emit PermissionManagerSet(msg.sender, _permissionManager);

        return true;
    }

    /**
     * @dev Sets FeeAddress to `_newFeeAddress`.
     *
     * Requirements:
     *
     * - the caller must have `FEE_MANAGER_ROLE` admin role.
     */
    function setFeeAddress(address _newFeeAddress) external onlyFeeManager returns (bool status) {
        feeAddress = _newFeeAddress;

        emit FeeAddressSet(msg.sender, _newFeeAddress);

        return true;
    }

    /**
     * @dev Sets FeeAmount to `_feeAmount`.
     *
     * Requirements:
     *
     * - the caller must have `FEE_MANAGER_ROLE` admin role.
     */
    function setFeeAmount(uint256 _feeAmount) external onlyFeeManager returns (bool status) {
        feeAmount = _feeAmount;

        emit FeeAmountSet(msg.sender, _feeAmount);

        return true;
    }
}