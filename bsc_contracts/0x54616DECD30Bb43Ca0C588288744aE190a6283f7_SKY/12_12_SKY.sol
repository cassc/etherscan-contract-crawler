// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SKY is IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "SKY COIN";
    string private _symbol = "SKY";

    mapping(address => bool) public pairs;
    mapping(address => bool) public excludeFee;
    address public mainPair;
    address public otherTokenAddress;

    bool public buySwitch;
    address public receiveBuyAdd;
    uint public buyFee;

    address public dividendAdd;
    address public marketAdd;

    uint256 public sellBurnFee = 5;
    uint256 public sellDividendFee = 3;
    uint256 public sellMarketFee = 2;
    uint256 public totalFee;

    mapping(address => bool) public deadAddress;

    constructor(
        uint256 _maxSupply,
        address _dividendAdd,
        address _marketAdd,
        address _usdtAddress,
        address _iUniswapV2Router02Add,
        address _receiveAdd
    ) {
        dividendAdd = _dividendAdd;
        marketAdd = _marketAdd;

        IUniswapV2Router02 iUniswapV2Router02 = IUniswapV2Router02(
            _iUniswapV2Router02Add
        );
        IUniswapV2Factory iUniswapV2Factory = IUniswapV2Factory(
            iUniswapV2Router02.factory()
        );
        address pair1 = iUniswapV2Factory.createPair(
            address(this),
            iUniswapV2Router02.WETH()
        );
        // token1 = SKY , token2 = USDT
        address pair2 = iUniswapV2Factory.createPair(
            address(this),
            _usdtAddress
        );
        mainPair = pair2;
        otherTokenAddress = _usdtAddress;
        pairs[pair1] = true;
        pairs[pair2] = true;
        excludeFee[_msgSender()] = true;
        excludeFee[dividendAdd] = true;
        excludeFee[marketAdd] = true;
        excludeFee[_receiveAdd] = true;
        excludeFee[0x000000000000000000000000000000000000dEaD] = true;
        deadAddress[0x000000000000000000000000000000000000dEaD] = true;
        _mint(_receiveAdd, _maxSupply * 10 ** decimals());
    }

    function updatePair(address _pair, bool _state) public onlyOwner {
        require(_pair != address(0), "ERROR:ZERO_ADDRESS");
        pairs[_pair] = _state;
    }

    function updateExcludeFee(address _address, bool _state) public onlyOwner {
        require(_address != address(0), "ERROR:ZERO_ADDRESS");
        excludeFee[_address] = _state;
    }

     function updateBatchExcludeFee(address[] calldata _addresses, bool _state) public onlyOwner {
        require(_addresses.length  > 0, "ERROR:ZERO_ADDRESS");
        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "ERROR:ZERO_ADDRESS");
            excludeFee[_addresses[i]] = _state;
        }
    }

    function updateMainPair(address _mainPair) public onlyOwner{
        require(_mainPair != address(0), "ERROR:ZERO_ADDRESS");
        mainPair = _mainPair;
    }


    function updateOtherTokenAdd(address _otherTokenAdd) public onlyOwner{
        require(_otherTokenAdd != address(0), "ERROR:ZERO_ADDRESS");
        otherTokenAddress = _otherTokenAdd;
    }

    function updateBuySwitch(bool _buySwitch) public onlyOwner{
        buySwitch = _buySwitch;
    } 

    function updateReceiveBuyAdd(address _receiveBuyAdd) public onlyOwner{
        require(_receiveBuyAdd != address(0), "ERROR:ZERO_ADDRESS");
        receiveBuyAdd = _receiveBuyAdd;
    }

    function updateBuyFee(uint _buyFee) public onlyOwner{
        buyFee = _buyFee;
    }

    function updateDividendAdd(address _dividendAdd) public onlyOwner{
        dividendAdd = _dividendAdd;
    }

    function updateMarketAdd(address _marketAdd) public onlyOwner{
        marketAdd = _marketAdd;
    }

    function updateSellBurnFee(uint _sellBurnFee) public onlyOwner{
        sellBurnFee = _sellBurnFee;
    }

    function updateDividendFee(uint _sellDividendFee) public onlyOwner{
        sellDividendFee = _sellDividendFee;
    }

    function updateMarketFee(uint _sellMarketFee) public onlyOwner{
        sellMarketFee = _sellMarketFee;
    }

    function setDeadAddress(
        address _deadAddress,
        bool _isDaedAdd
    ) public onlyOwner {
        deadAddress[_deadAddress] = _isDaedAdd;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        bool isSwap = pairs[from] || pairs[to];

        if (isSwap) {
            if (pairs[from]) {
                if (_isRemoveLiquidity()) {
                    _standardTransfer(from, to, amount);
                    _afterTokenTransfer(from, to, amount);
                    return;
                }
            }
            if (pairs[to]) {
                if (_isAddLiquidity()) {
                    _standardTransfer(from, to, amount);
                    _afterTokenTransfer(from, to, amount);
                    return;
                }
            }
            if (pairs[from] && !excludeFee[to]) { 
                require(buySwitch,"ERC20: can't buy");
            }
            if (excludeFee[from] || excludeFee[to]) {
                // whiteList
                _standardTransfer(from, to, amount);
            } else {
                _transferWithFee(from, to, amount);
            }
        } else {
            // normal transfer
            if (deadAddress[to]) {
                _burn(from, amount);
            } else {
                _standardTransfer(from, to, amount);
            }
        }

        _afterTokenTransfer(from, to, amount);
    }

    function _standardTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _transferWithFee(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (pairs[from]) {
            //buy
            uint256 buyFeeAmount = amount.mul(buyFee).div(100);
            totalFee += buyFeeAmount;
            uint256 tAmount = amount.sub(buyFeeAmount);
            _balances[receiveBuyAdd] += buyFeeAmount;
            emit Transfer(from, receiveBuyAdd, buyFeeAmount);

            _balances[from] -= amount;
            _balances[to] += tAmount;
            emit Transfer(from, to, tAmount);
            
        } else {
            //sell
            uint256 sellBurnAmount = amount.mul(sellBurnFee).div(100);
            totalFee += sellBurnAmount;
            uint256 tAmount = amount.sub(sellBurnAmount);
            _burn(from,sellBurnAmount);
            
            uint256 sellDividendAmount = amount.mul(sellDividendFee).div(100);
            totalFee += sellDividendAmount;
            tAmount = tAmount.sub(sellDividendAmount);
            _balances[dividendAdd] += sellDividendAmount;
            emit Transfer(from, dividendAdd, sellDividendAmount);

            uint256 sellMarketAmount = amount.mul(sellMarketFee).div(100);
            totalFee += sellMarketAmount;
            tAmount = tAmount.sub(sellMarketAmount);  
            _balances[marketAdd] += sellMarketAmount;
            emit Transfer(from, marketAdd, sellMarketAmount);
            
            _balances[from] -= amount;
            _balances[to] += tAmount;
            emit Transfer(from, to, tAmount);
        }
    }

    function _isAddLiquidity() internal view returns (bool isAdd) {
        IUniswapV2Pair pair = IUniswapV2Pair(mainPair);
        (uint r0, uint256 r1, ) = pair.getReserves();

        address tokenOther = otherTokenAddress;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }
        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove) {
        IUniswapV2Pair pair = IUniswapV2Pair(mainPair);
        (uint r0, uint256 r1, ) = pair.getReserves();

        address tokenOther = otherTokenAddress;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
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
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}