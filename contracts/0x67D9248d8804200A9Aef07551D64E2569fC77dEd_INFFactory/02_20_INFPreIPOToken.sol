// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/IINFPermissionManager.sol";

contract INFPreIPOToken is IERC20, IERC20Metadata, AccessControlEnumerable {
    // BEGIN: CONSTANTS
    event LogSetPermissionManager(address manager);

    uint8 public constant override decimals = 18;
    string constant private namePrefix = "INF Pre-IPO wrapped token for "; 
    string constant private symbolPrefix = "INF-"; 
    // Token admin role controls token-related management actions
    bytes32 public constant TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");

    // INF-Token Storage
    IINFPermissionManager public permissionManager;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;

    string public override name;
    string public override symbol;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     *
     * Then setup default admin roles and mint {amount} tokens.
     */
    constructor(
        address to,
        string memory name_,
        string memory symbol_,
        uint256 amount,
        address permissionManagerAddress
    ) {
        // Set name and symbol
        name = string(abi.encodePacked(namePrefix, name_));
        symbol = string(abi.encodePacked(symbolPrefix, symbol_));

        // Set default roles
        _setupRole(DEFAULT_ADMIN_ROLE, to);
        _setupRole(TOKEN_ADMIN_ROLE, msg.sender);
        _setupRole(TOKEN_ADMIN_ROLE, to);

        permissionManager = IINFPermissionManager(permissionManagerAddress);

        // Pre-mint tokens
        _mint(to, amount);
      
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function mint(address to, uint256 amount) public onlyRole(TOKEN_ADMIN_ROLE) {
        _mint(to, amount);
    }

    /***** BEGIN: ERC-20 Burnable functions *****/

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {

        uint256 currentAllowance = allowance[account][msg.sender];

        if (currentAllowance != type(uint256).max) allowance[account][msg.sender] = currentAllowance - amount;
        
        _burn(account, amount);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `to`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address to, uint256 amount) internal virtual {
        require(to != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(address(0), to, amount);

    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {

        balanceOf[account] -= amount;
        
        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

    }

    /***** BEGIN: ERC-20 modified functions *****/

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * - `recipient` must be whitelisted
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
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
     * - `recipient` must be whitelisted
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        virtual
        override
        returns (bool)
    {
        uint256 currentAllowance = allowance[sender][msg.sender];

        if (currentAllowance != type(uint256).max) allowance[sender][msg.sender] = currentAllowance - amount;

        _transfer(sender, recipient, amount);

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        virtual
    {
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            balanceOf[sender] = senderBalance - amount;
        }

        (bool exempt, uint256 fee, uint256 feePrecision, address feeRecipient) = 
            permissionManager.getStatusAndFee(sender, recipient);

        // Check transfer fee
        if (!exempt) {
            fee = amount * fee / feePrecision;
            require(fee < amount, "ERC20: transfer fee exceeds total amount sent");
            balanceOf[feeRecipient] += fee;
            uint256 finalAmount = amount - fee;
            balanceOf[recipient] += finalAmount;
            emit Transfer(sender, feeRecipient, fee);
            emit Transfer(sender, recipient, finalAmount);
        } else {
            balanceOf[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }

    }

    /***** END: ERC-20 modified functions *****/

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function setPermissionManager(IINFPermissionManager manager) external {
        permissionManager = manager;
        emit LogSetPermissionManager(address(manager));
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}