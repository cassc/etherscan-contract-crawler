// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract EURB is AccessControl, ERC20Burnable, Ownable, Pausable {

    uint8 private _decimals;
    uint256 public _feePercentage = 1000;    // Fee percentage's default is at 1%, the number of zero dictates the number of digit after the decimal 
    string private _uri;
    string private _name;
    string private _symbol;
    address public _feeReceiver;
    
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isFrozen;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ASSET_PROTECTION_ROLE = keccak256("ASSET_PROTECTION_ROLE");

    event Mint(address indexed to, uint256 amount);
    event MintFinished(address indexed account, bool isFinished);
    event Burn(address indexed to, uint256 amount);
    event BurnFinished(address indexed account, bool isFinished);

    constructor() payable ERC20("","") {}

    modifier notFrozen() {
        require(!isFrozen[_msgSender()], "EURB: Account is frozen");
        _;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {decimals} is
     * set in constructor.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the uri of the bank balance.
     */
    function uri() public view returns (string memory) {
        return _uri;
    }

    function setUrl(string memory uri_) public onlyOwner{
        _uri = uri_;
    }

    function setName(string memory name_) public onlyOwner{
        _name = name_;
    }

    function setSymbol(string memory symbol_) public onlyOwner{
        _symbol = symbol_;
    }

    function setDecimals(uint8 decimals_) public onlyOwner{
        _decimals = decimals_;
    }

    function setFeePercentage(uint256 feePercentage_) public onlyOwner{
        require(feePercentage_ <= 100000, "EURB: Fee percentage exceeds 100%");
        _feePercentage = feePercentage_;
    }

    function setFeeReceiver(address feeReceiver_) public onlyOwner{
        _feeReceiver = feeReceiver_;
    }

    function excludeFromFee(address addr_) public onlyOwner{
        isExcludedFromFee[addr_] = true;
    }

    function includeInFee(address addr_) public onlyOwner{
        isExcludedFromFee[addr_] = false;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 amount)
        public
        whenNotPaused
    {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "EURB: Caller is not a minter"
        );
        _mint(account, amount);
        emit Mint(account, amount);
    }

    function burn(uint256 amount) public override whenNotPaused {
        require(
            hasRole(BURNER_ROLE, _msgSender()) || hasRole(ASSET_PROTECTION_ROLE, _msgSender()),
            "EURB: Caller does not have burner role nor asset proctection role"
        );
        _burn(owner(), amount);
        emit Burn(owner(), amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        virtual
        override
        whenNotPaused
    {
        require(
            hasRole(BURNER_ROLE, _msgSender()) || hasRole(ASSET_PROTECTION_ROLE, _msgSender()),
            "EURB: Caller does not have burner role nor asset proctection role"
        );
        super.burnFrom(account, amount);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        notFrozen
        returns (bool)
    {
        transferFee(_msgSender(), recipient, amount);

        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused notFrozen returns (bool) {
        require(sender != _msgSender(), "EURB: Caller is sender");
        require(!isFrozen[sender], "EURB: Sender is frozen");

        transferFee(sender, recipient, amount);

        uint256 remained = allowance(sender, _msgSender()) - amount;
        _approve(sender, _msgSender(), remained);
        return true;
    }

    /**
     * @dev Function set Frozen Account .
     */
    function freezeAccount(address _account) public {
        require(
            hasRole(ASSET_PROTECTION_ROLE, _msgSender()),
            "EURB: Caller does not have asset protection role"
        );
        require(
            _account != owner(),
            "EURB: Can not freeze owner"
        );

        require(isFrozen[_account] != true, "EURB: Already froze account");
        isFrozen[_account] = true;
    }

    function unFreezeAccount(address _account) public {
        require(
            hasRole(ASSET_PROTECTION_ROLE, _msgSender()),
            "EURB: Caller does not have asset protection role"
        );
        require(isFrozen[_account] != false, "EURB: Already unfroze account");
        isFrozen[_account] = false;
    }

    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override {
        require(newOwner != address(0), "EURB: new owner is the zero address");
        require(newOwner != owner(), "EURB: new owner is current owner");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s owner role.
     */
    function grantRole(bytes32 role, address account) public override onlyOwner{
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s owner role.
     */
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    /**
     * Change how many tokens given spender is allowed to transfer from message
     * spender.  In order to prevent double spending of allowance, this method
     * receives assumed current allowance value as an argument.  If actual
     * allowance differs from an assumed one, this method just returns false.
     *
     * @param _spender address to allow the owner of to transfer tokens from
     *        message sender
     * @param _currentValue assumed number of tokens currently allowed to be
     *        transferred
     * @param _newValue number of tokens to allow to transfer
     * @return true if token transfer was successfully approved, false otherwise
     */
    function safeApprove(
        address _spender,
        uint256 _currentValue,
        uint256 _newValue
    ) public returns (bool) {
        if (allowance(msg.sender, _spender) == _currentValue)
            return approve(_spender, _newValue);
        else return false;
    }

    
    function transferFee(address sender, address recipient, uint256 amount) internal {
        uint256 txFee = 0;
        if(sender != owner() && sender != _feeReceiver && !isExcludedFromFee[sender] && _feePercentage > 0) {
            txFee = amount * _feePercentage / 100000;
            _transfer(sender, _feeReceiver, txFee);
            
        }
        _transfer(sender, recipient, amount - txFee);
    }
}