// contracts/TokenTraxx.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/** 
*@title TokenTraxx ERC20 Token contract based on Openzepplin smart contract
*@author Genesis Block Team Ashish Madan, Tanuj Nigam, Gokul, Jitin Jain 
*/
// This is the main building block for smart contracts.
contract TokenTraxx is Context, AccessControlEnumerable, ERC20Pausable {
    uint8 private immutable _decimals;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /**
     * @dev The constructor take name symbol decimals and cap.
     * Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     *
     *  - a minter role that allows for token minting (creation)
     *  - a pauser role that allows to stop all token transfers
     *
     * This contract uses {AccessControl} to lock permissioned functions using the
     * different roles - head to its documentation for details.
     *
     * The account that deploys the contract will be granted the minter and pauser
     * roles, as well as the default admin role, which will let it grant both minter
     * and pauser roles to other accounts.
     *
     *
     * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
     *
     * @param name_ name of the token 
     * @param symbol_ synbol of the token 
     * @param decimals_ number of decimals of the token (18) 
     * @param initialAccount address of the account to which intial tokems to be minted to
     * @param initialBalance number of token to be initially minted
     * @param initialAdmin address on the admin 
     * @param initialMinter address on the minter   
     * @param initialPauser address on the pauser 
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 cap_,
        address initialAccount,
        uint256 initialBalance,
        address initialAdmin,
        address initialMinter,
        address initialPauser
    ) ERC20(name_, symbol_) {
        require(bytes(name_).length > 0, "Token: name is required");
        require(bytes(symbol_).length > 0, "Token: length is required");
        require(cap_ > 0, "Token: cap is 0");
        require(decimals_ > 0, "Token: decimals is 0");
        require(
            initialAdmin != address(0),
            "Token: admin cannot be zero address"
        );
        require(
            initialMinter != address(0),
            "Token: minter cannot be zero address"
        );
        require(
            initialPauser != address(0),
            "Token: pauser cannot be zero address"
        );
        _cap = cap_;
        _decimals = decimals_;
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialMinter);
        _grantRole(PAUSER_ROLE, initialPauser);
        if (initialBalance > 0) {
            require(
                initialAccount != address(0),
                "Token: initial account cannot be zero address"
            );
            require(
                ERC20.totalSupply() + initialBalance <= cap_,
                "Token: cap exceeded"
            );
            _mint(initialAccount, initialBalance);
        }
    }

    /**
     * @dev Returns the decimal used for the contract
     * @return uint8 the decimals
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev We can not mint more than the cap.
     * @param account address of the account to which token will be minted
     * @param amount number of tokens to be minted 
     */
    function mint(address account, uint256 amount) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Token: must have minter role to mint"
        );
        //make sure there is no logc in cap() function 
        require(ERC20.totalSupply() + amount <= _cap, "Token: cap exceeded");
        super._mint(account, amount);
    }

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    uint256 private immutable _cap;

    /**
     * @dev Returns the cap on the token's total supply.
     * @return uint256 cap on the token's total supply
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * @notice the caller must have the `PAUSER_ROLE`.
     */
    function pause() external virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Token: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * @notice the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Token: must have pauser role to unpause"
        );
        _unpause();
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * We check the roles to have atleast one admin before it can be removed 
     * @param role from which the account is to be removes
     * @param account address of the acccount to be removed 
     */
    function revokeRole(bytes32 role, address account)
        external
        override
        onlyRole(getRoleAdmin(role))
    {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(
               getRoleMemberCount(role) > 1,
                "Token: require atleast one admin"
            );
        }
        super._revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     * We check the roles to have atleast one admin before it can be removed 
     * @param role from which the account is to be removes
     * @param account address of the acccount to be removed 
     */
    function renounceRole(bytes32 role, address account)
        external
        virtual
        override
    {
       require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        if (role == DEFAULT_ADMIN_ROLE) {
            require(
                 getRoleMemberCount(role) > 1,
                "Token: require atleast one admin"
            );
        }
        super.renounceRole(role, account);
    }
}