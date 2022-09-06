/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "TestTravelC: _newOwner is zero address");
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
 interface ERC20Interface {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8); 
 
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address owner, address spender) external view returns (uint256);
  
    function transfer(address recipient, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 tokens) external returns (bool success);

    event Transfer(address indexed sender, address indexed recipient, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract TravelC is ERC20Interface, Owned, SafeMath {
 
    string private _symbol = "TRAVELC";
    string private _name = "TRAVELC TOKEN";
    uint8 private _decimals = 6;
    
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
   
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        _totalSupply = 1000000000 * 10**uint(_decimals);
        _balances[0xc7F152cC48E9BdC4848fFb183433054BE415b9fA] = _totalSupply;
       emit Transfer(address(0), 0xc7F152cC48E9BdC4848fFb183433054BE415b9fA, _totalSupply);
    }
    
    // ------------------------------------------------------------------------
    // Returns the name of the token.
    // ------------------------------------------------------------------------
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // ------------------------------------------------------------------------
    // Returns the symbol of the token, usually a shorter version of the name
    // ------------------------------------------------------------------------
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    // ------------------------------------------------------------------------
    // Returns the symbol of the token, usually a shorter version of the name
    // 
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens in existence.
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner)  public override view returns (uint256 balance) {
        return _balances[tokenOwner];
    }
    
    /**
     * @dev See {IERC20-allowance}.
     *
     * Returns the amount of tokens approved by the owner that can be
     * transferred to the spender's account
     *
     */
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return _allowances[tokenOwner][spender];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 tokens) public override returns (bool success) {
        _transfer(msg.sender, recipient, tokens);
        return true;
    }
    
     /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.

     * Token owner can approve for spender to transferFrom(...) tokens
     * from the token owner's account
     *
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
     * recommends that there are no checks for the approval double-spend attack
     * as this should be implemented in user interfaces 
     */
    function approve(address spender, uint256 tokens) public override returns (bool success) {
        _approve(msg.sender, spender, tokens);
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
    function transferFrom(address sender, address recipient, uint256 tokens) public override returns (bool success) {
        
        _transfer(sender, recipient, tokens);
        
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= tokens, "TestTravelC: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - tokens);
        }
        
        return true;
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    receive() external payable {
        revert();
    }
    
    function _transfer(address sender, address recipient, uint256 tokens) internal virtual {
        
        require(sender != address(0), "TestTravelC: transfer from the zero address");
        require(recipient != address(0), "TestTravelC: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= tokens, "TestTravelC: transfer amount exceeds balance");
        _balances[sender] = safeSub(senderBalance, tokens);
        
        _balances[recipient] = safeAdd(_balances[recipient], tokens);
        emit Transfer(sender, recipient, tokens);

    }
    
     /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 tokens) internal virtual {

        require(owner != address(0), "TestTravelC: approve from the zero address");
        require(spender != address(0), "TestTravelC: approve to the zero address");

        _allowances[owner][spender] = tokens;
        emit Approval(owner, spender, tokens);
        
    }

}