// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract AIR is IERC20, Ownable, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address public Minter;
    uint256 public TaxPercentage;

    constructor(string memory name_, string memory symbol_, address _minter, uint256 _taxPercentage, uint256 _supply) {
        _name = name_;
        _symbol = symbol_;
        TaxPercentage = _taxPercentage;
        Minter = _minter;
        _totalSupply = _supply * 10 ** uint256(decimals());
        _balances[_msgSender()] = totalSupply();
        emit Transfer(address(0), _msgSender(), totalSupply());
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function changeAdmin(address _minter) external onlyOwner
    {
      require(_minter != address(0), "changeAdmin: Not good.");
      Minter = _minter;
    }

    function changeTaxPercentage(uint256 _taxPercentage) external onlyOwner
    {
      require(_taxPercentage <= 10000, "changeTaxPercentage: Needs to be lower than 10000");
      TaxPercentage = _taxPercentage;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(from, to, amount);

        uint256 currentAllowance = _allowances[from][_msgSender()];
        require(
            currentAllowance >= amount,
            "APTOKEN:transferFrom:ALLOWANCE_EXCEEDED: Transfer amount exceeds allowance."
        );
        unchecked {
            _approve(from, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "APTOKEN:decreaseAllowance:ALLOWANCE_UNDERFLOW: Subtraction results in sub-zero allowance."
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "APTOKEN:_transfer:FROM_ZERO: Cannot transfer from the zero address.");
        require(to != address(0), "APTOKEN:_transfer:TO_ZERO: Cannot transfer to the zero address.");
        require(amount > 0, "APTOKEN:_transfer:ZERO_AMOUNT: Transfer amount must be greater than zero.");
        require(amount <= _balances[from], "APTOKEN:_transfer:INSUFFICIENT_BALANCE: Transfer amount exceeds balance.");

        uint256 tax = amount.mul(TaxPercentage).div(10000);
        uint256 taxedAmount = amount.sub(tax);

        _beforeTokenTransfer(from, to, amount);

        _balances[from] -= amount;
        _balances[to] += taxedAmount;
        // _moveDelegates(delegates[from], delegates[to], uint224(taxedAmount));

        if (tax > 0) {
            _balances[Minter] += tax;

            // _moveDelegates(delegates[from], delegates[address(treasuryHandler)], uint224(tax));

            emit Transfer(from, Minter, tax);
        }

        // treasuryHandler.afterTransferHandler(from, to, amount);
        _afterTokenTransfer(from, to, amount);

        emit Transfer(from, to, taxedAmount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}