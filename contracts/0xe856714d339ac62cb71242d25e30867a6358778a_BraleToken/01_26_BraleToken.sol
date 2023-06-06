// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @dev Brale's token contract.
 *
 * This contract is used directly for both our and our clients' tokens.
 */
/// @custom:security-contact [email protected]
contract BraleToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    /**
     * @dev The contract version follows Semantic Versioning 2.0.0. MAJOR
     * versions contain breaking API changes, MINOR backwards compatible
     * functionality, and PATCH backwards compatible bug fixes.
     * For details, see https://semver.org/spec/v2.0.0.html.
     */
    string public constant CONTRACT_VERSION = "0.1.7";

    /**
     * @dev For `ControlledAccessType.Allow`, {CONTROLLED_ACCESS_ROLE} contains
     * a list of addresses allowed interaction with the contract. All other
     * addresses are denied.
     *
     * For `ControlledAccessType.Deny`, {CONTROLLED_ACCESS_ROLE} contains a
     * list of addresses denied interaction with the contract. All other
     * addresses are allowed.
     *
     * For details, see {ControlledAccessType}.
     */
    bytes32 public constant CONTROLLED_ACCESS_ROLE =
        keccak256("CONTROLLED_ACCESS_ROLE");

    /**
     * @dev Role required for `mint`.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Role required for `allow` and `deny`, which add or remove addresses
     * from {CONTROLLED_ACCESS_ROLE} for allowlist or denylist functionality.
     */
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    /**
     * @dev Role required for `pause` and `unpause`.
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Role required to propose contract upgrades.
     */
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /**
     * @dev Clients decide between allowlist or denylist functionality on token
     * creation.
     *
     * For `ControlledAccessType.Allow`, {CONTROLLED_ACCESS_ROLE} contains a
     * list of addresses allowed interaction with the contract. All other
     * addresses are denied.
     *
     * For `ControlledAccessType.Deny`, {CONTROLLED_ACCESS_ROLE} contains a
     * list of addresses denied interaction with the contract. All other
     * addresses are allowed.
     *
     * This value is immutable: it can only be set once during construction.
     */
    enum ControlledAccessType {
        Deny,
        Allow
    }

    /**
     * @dev Stores the contract's controlled access type. For details, see
     * {ControlledAccessType}.
     */
    ControlledAccessType private controlledAccessType;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Passes {name_} and {symbol_} to parent initializers. Sets the value
     * for {controlledAccessType} and configures roles for {automator_},
     * {client_}, {defaultAdmin_}, and {upgrader_} based on the value of
     * {controlledAccessType}. The deployer's roles are revoked.
     *
     * Recommendations: {automator_} should use a multisig contract.
     * {defaultAdmin_} credentials should be stored offline.
     *
     * These values are immutable: they can only be set once during
     * construction.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address automator_,
        address client_,
        address defaultAdmin_,
        address upgrader_,
        ControlledAccessType controlledAccessType_
    ) external initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init(name_);
        __UUPSUpgradeable_init();

        controlledAccessType = controlledAccessType_;
        if (controlledAccessType_ == ControlledAccessType.Allow) {
            // address(0) is the `from` account on mints
            _grantRole(CONTROLLED_ACCESS_ROLE, address(0));
            _grantRole(CONTROLLED_ACCESS_ROLE, automator_);
            _grantRole(CONTROLLED_ACCESS_ROLE, client_);
        }

        _grantRole(MINTER_ROLE, automator_);
        _grantRole(MODERATOR_ROLE, automator_);
        _grantRole(PAUSER_ROLE, automator_);

        _grantRole(UPGRADER_ROLE, upgrader_);

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev See {ERC20Upgradeable-_mint}.
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev See {ERC20Upgradeable-approve}.
     */
    function approve(
        address spender,
        uint256 amount
    )
        public
        override
        whenAllowed(_msgSender())
        whenAllowed(spender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    /**
     * @dev See {ERC20Upgradeable-increaseAllowance}.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        override
        whenAllowed(_msgSender())
        whenAllowed(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @dev See {ERC20Upgradeable-decreaseAllowance}.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public override whenAllowed(_msgSender()) returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * @dev See {PausableUpgradeable-_pause}.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev See {PausableUpgradeable-_unpause}.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev See {draft-ERC20PermitUpgradeable-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override whenAllowed(owner) whenAllowed(spender) {
        return super.permit(owner, spender, value, deadline, v, r, s);
    }

    /**
     * @dev Modifier that checks that an account does or does not have
     * {CONTROLLED_ACCESS_ROLE} based on `controlledAccessType`. Reverts
     * with a standardized message including the required role.
     *
     * The revert reason format is given by the following regular expressions:
     *
     * /^AccessControl: account (0x[0-9a-f]{40}) does not have controlled access via role (0x[0-9a-f]{64})$/
     */
    modifier whenAllowed(address account) {
        if (controlledAccessType == ControlledAccessType.Allow) {
            require(
                hasRole(CONTROLLED_ACCESS_ROLE, account),
                _controlledAccessError(account)
            );
        } else {
            require(
                !hasRole(CONTROLLED_ACCESS_ROLE, account),
                _controlledAccessError(account)
            );
        }
        _;
    }

    /**
     * @dev For `ControlledAccessType.Allow`, returns `true` if `account` has
     * been granted {CONTROLLED_ACCESS_ROLE}.
     *
     * For `ControlledAccessType.Deny`, returns `true` if `account` has not been
     * granted {CONTROLLED_ACCESS_ROLE}.
     */
    function isAllowed(address account) external view returns (bool) {
        if (controlledAccessType == ControlledAccessType.Allow) {
            return hasRole(CONTROLLED_ACCESS_ROLE, account);
        } else {
            return !hasRole(CONTROLLED_ACCESS_ROLE, account);
        }
    }

    /**
     * @dev For `ControlledAccessType.Allow`, grants {CONTROLLED_ACCESS_ROLE} to
     * `accounts`.
     *
     * For `ControlledAccessType.Deny`, revokes {CONTROLLED_ACCESS_ROLE} from
     * `accounts`.
     *
     * Requirements:
     *
     * - the caller must have {MODERATOR_ROLE}.
     */
    function allow(
        address[] calldata accounts
    ) external onlyRole(MODERATOR_ROLE) {
        if (controlledAccessType == ControlledAccessType.Allow) {
            for (uint256 i = 0; i < accounts.length; i++) {
                _grantRole(CONTROLLED_ACCESS_ROLE, accounts[i]);
            }
        } else {
            for (uint256 i = 0; i < accounts.length; i++) {
                _revokeRole(CONTROLLED_ACCESS_ROLE, accounts[i]);
            }
        }
    }

    /**
     * @dev For `ControlledAccessType.Allow`, revokes {CONTROLLED_ACCESS_ROLE}
     * from `accounts`.
     *
     * For `ControlledAccessType.Deny`, grants {CONTROLLED_ACCESS_ROLE} to
     * `accounts`.
     *
     * Requirements:
     *
     * - the caller must have {MODERATOR_ROLE}.
     */
    function deny(
        address[] calldata accounts
    ) external onlyRole(MODERATOR_ROLE) {
        if (controlledAccessType == ControlledAccessType.Allow) {
            for (uint256 i = 0; i < accounts.length; i++) {
                _revokeRole(CONTROLLED_ACCESS_ROLE, accounts[i]);
            }
        } else {
            for (uint256 i = 0; i < accounts.length; i++) {
                _grantRole(CONTROLLED_ACCESS_ROLE, accounts[i]);
            }
        }
    }

    /**
     * @dev See {ERC20Upgradeable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused whenAllowed(from) whenAllowed(to) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     */
    function _authorizeUpgrade(
        address
    ) internal view override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev Creates controlled access error with a standardized message.
     */
    function _controlledAccessError(
        address account
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " does not have controlled access via role ",
                    StringsUpgradeable.toHexString(
                        uint256(CONTROLLED_ACCESS_ROLE),
                        32
                    )
                )
            );
    }
}