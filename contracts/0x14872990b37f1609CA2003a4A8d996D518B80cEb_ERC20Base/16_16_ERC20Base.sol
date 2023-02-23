// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@oz-upgradeable/access/AccessControlUpgradeable.sol";
import "@oz-upgradeable/proxy/utils/Initializable.sol";
import "@oz-upgradeable/security/PausableUpgradeable.sol";
import "@oz-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@oz-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@oz-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";

/**
 * @title Base ERC20 token contract for Origami Governance Tokens
 * @author Origami Inc.
 * @custom:security-contact [email protected]
 */
contract ERC20Base is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20CappedUpgradeable
{
    /// @notice the role hash for granting the ability to pause the contract. By default, this role is granted to the contract admin.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /// @notice the role hash for granting the ability to mint new governance tokens. By default, this role is granted to the contract admin.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice the role hash for granting the ability to burn governance tokens.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    /// @notice the role has for granting the ability to transfer governance tokens. By default, this role is granted to the contract admin. This is also typically granted to the DAO's treaury multisig for distributing compensation in the form of governance tokens.
    bytes32 public constant TRANSFERRER_ROLE = keccak256("TRANSFERRER_ROLE");

    /// @dev Denotes whether or not the contract allows buring tokens. By default, this is disabled.
    bool private _burnEnabled;
    /// @notice Denotes whether or not the contract allows token transfers. By default, this is disabled.
    bool private _transferEnabled;

    /// @dev monitoring: this is fired when the transferEnabled state is changed.
    event TransferEnabled(address indexed caller, bool value);
    /// @dev monitoring: this is fired when the burnEnabled state is changed.
    event BurnEnabled(address indexed caller, bool value);

    /**
     * @notice the constructor is not used since the contract is upgradeable except to disable initializers in the implementations that are deployed.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the ERC20Base contract. It is called during contract deployment.
     * @param admin the address of the contract admin. This address receives all roles by default and should be used to delegate them to DAO committees and/or permanent members.
     * @param tokenName the name of the token. Typically this is the name of the DAO.
     * @param tokenSymbol the symbol of the token. Typically this is a short abbreviation of the DAO's name.
     * @param supplyCap cap on the total supply mintable by this contract.
     */
    function initialize(address admin, string memory tokenName, string memory tokenSymbol, uint256 supplyCap)
        public
        initializer
    {
        require(admin != address(0), "Admin address cannot be zero");

        __AccessControl_init();
        __ERC20Burnable_init();
        __ERC20Capped_init(supplyCap);
        __ERC20_init(tokenName, tokenSymbol);
        __Pausable_init();

        // grant roles to the admin
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);

        // disable burning and transfers by default
        _burnEnabled = false;
        _transferEnabled = false;
    }

    /// @inheritdoc ERC20Upgradeable
    function name() public view virtual override returns (string memory) {
        return super.name();
    }

    /// @inheritdoc ERC20Upgradeable
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return super.balanceOf(owner);
    }

    /**
     * @notice indicates whether or not governance tokens are burnable
     * @return true if tokens are burnable, false otherwise.
     */
    function burnable() public view returns (bool) {
        return _burnEnabled;
    }

    /**
     * @notice this function enables the burning of governance tokens. Only the contract admin can call this function.
     * @dev this emits an event indicating that the burnable state has been set to enabled and by whom.
     */
    function enableBurn() public onlyRole(DEFAULT_ADMIN_ROLE) whenNotBurnable {
        _burnEnabled = true;
        emit BurnEnabled(_msgSender(), _burnEnabled);
    }

    /**
     * @notice this function disables the burning of governance tokens. Only the contract admin can call this function.
     * @dev this emits an event indicating that the burnable state has been set to disabled and by whom.
     */
    function disableBurn() public onlyRole(DEFAULT_ADMIN_ROLE) whenBurnable {
        _burnEnabled = false;
        emit BurnEnabled(_msgSender(), _burnEnabled);
    }

    /**
     * @notice indicates whether or not governance tokens are transferrable
     * @return true if tokens are transferrable, false otherwise.
     */
    function transferrable() public view returns (bool) {
        return _transferEnabled;
    }

    /**
     * @notice this function enables transfers of governance tokens. Only the contract admin can call this function.
     * @dev this emits an event indicating that the transferrable state has been set to enabled and by whom.
     */
    function enableTransfer() public onlyRole(DEFAULT_ADMIN_ROLE) whenNontransferrable {
        _transferEnabled = true;
        emit TransferEnabled(_msgSender(), _transferEnabled);
    }

    /**
     * @notice this function disables transfers of governance tokens. Only the contract admin can call this function.
     * @dev this emits an event indicating that the transferrable state has been set to disabled and by whom.
     */
    function disableTransfer() public onlyRole(DEFAULT_ADMIN_ROLE) whenTransferrable {
        _transferEnabled = false;
        emit TransferEnabled(_msgSender(), _transferEnabled);
    }

    /**
     * @notice this function pauses the contract, restricting mints, transfers and burns regardless of the independent state of other configurations.
     * @dev this is only callable by an address that has the PAUSER_ROLE
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice this function unpauses the contract
     * @dev this is only callable by an address that has the PAUSER_ROLE
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice this function mints governance token to the recipient's wallet. An event is fired whenever new tokens are minted indicating who initiated the mint, where they were minted to and how many tokens were minted.
     * @dev this is only callable by an address that has the MINTER_ROLE. The Origami platform may call this function to mint new governance tokens in accordance with a DAO's charter. When it does so, they will always be minted to the treasury multisig.
     * @param to the address of the recipient's wallet.
     * @param amount the amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public virtual onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @notice this allows transfers when the transferrable state is enabled.
     * @dev this is overridden so we can apply the `whenTransferrable` modifier
     */
    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        override
        whenTransferrable
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    /**
     * @notice this allows transfers when the transferrable state is enabled.
     * @dev this is overridden so we can apply the `whenTransferrable` modifier
     */
    function transfer(address to, uint256 amount) public virtual override whenTransferrable returns (bool) {
        return super.transfer(to, amount);
    }

    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract implements interfaceID and interfaceID is not 0xffffffff, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// Start OpenZeppelin hooks --v

    /**
     * @inheritdoc ERC20Upgradeable
     * @dev this is overridden so we can apply the `whenNotPaused` modifier
     */
    // slither-disable-next-line dead-code
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override(ERC20Upgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @dev specify overrides
    function _mint(address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        super._mint(to, amount);
    }

    /// End OpenZeppelin hooks --^

    /// @dev this modifier allows us to ensure that something may only occur when burning is disabled
    modifier whenNotBurnable() {
        require(!burnable(), "Burnable: burning is enabled");
        _;
    }

    /// @dev this modifier allows us to ensure that something may only occur when burning is enabled
    modifier whenBurnable() {
        require(hasRole(BURNER_ROLE, _msgSender()) || burnable(), "Burnable: burning is disabled");
        _;
    }

    /// @dev this modifier allows us to ensure that something may only occur when transfers are disabled
    modifier whenNontransferrable() {
        require(!transferrable(), "Transferrable: transfers are enabled");
        _;
    }

    /// @dev this modifier allows us to ensure that something may only occur when the transfers are enabled
    modifier whenTransferrable() {
        require(hasRole(TRANSFERRER_ROLE, _msgSender()) || transferrable(), "Transferrable: transfers are disabled");
        _;
    }
}