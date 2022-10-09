// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

import "./SOCOUtils.sol";

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ISOCOAffiliate {
    function bind(address sender, address receiver) external;

    function append(address sender, uint256 amount) external;
}

interface ISOCOBonus {
    function append(address sender, uint256 amount) external;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SOCOERC20
contract SOCOERC20 is IERC20, Ownable {
    using SafeMath for uint256;

    uint8   constant private bonusRate     = 5;
    uint8   constant private affiliateRate = 5;
    uint256 constant private maxSupply     = 1000000000 * (10 ** 18);

    string  private _name;
    string  private _symbol;
    uint8   private _decimals;

    address    private _bonusAddr;
    ISOCOBonus private _bonusLike;

    address        private _affiliateAddr;
    ISOCOAffiliate private _affiliateLike;

    address         public  WBNBAddress;
    address         public  PancakeFactory;
    IPancakeFactory private _pancakeFactoryLike;

    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    constructor () {
        Ownable._initOwnable();

        _name     = "soccer one";
        _symbol   = "SOCO";
        _decimals = 18;

        // This is pancake address that exist BSC chain, never modify it
        WBNBAddress    = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        PancakeFactory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
        _pancakeFactoryLike = IPancakeFactory(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73));
        _mint(msg.sender, maxSupply);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function swapAddress() external view returns (address) {
        return _getSwapAddress();
    }

    function bonusAddress() external view returns (address) {
        return _bonusAddr;
    }

    function setBonusAddress(address bonusAddr) external onlyOwner {
        require(bonusAddr != address(0), "SOCO: the bonus is zero address");

        _bonusAddr = bonusAddr;
        _bonusLike = ISOCOBonus(bonusAddr);
    }

    function affiliateAddress() external view returns (address) {
        return _affiliateAddr;
    }

    function setAffiliateAddress(address affiliateAddr) external onlyOwner {
        require(affiliateAddr != address(0), "SOCO: the affiliate is zero address");

        _affiliateAddr = affiliateAddr;
        _affiliateLike = ISOCOAffiliate(affiliateAddr);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _safeTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _safeTransfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "SOCO: transfer amount exceeds allowance"));
        return true;
    }

    function burn(address account, uint256 amount) external virtual override returns (bool) {
        _burn(account, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "SOCO: decreased allowance below zero"));
        return true;
    }

    function _safeTransfer(address sender, address recipient, uint256 amount) internal virtual {
        // get swap address and check it
        address swapAddr = _getSwapAddress();
        if (swapAddr != address(0)) {
            require (isContract(swapAddr), "SOCO: invalid swap address");
        }

        // the normal transfer transaction(sender and recipient are user address) or add liquidity(recipient == swapAddr)
        if (sender != swapAddr) {
            _transfer(sender, recipient, amount);

            if (!isContract(sender) && !isContract(recipient)) {
                _affiliateLike.bind(sender, recipient);
            }
        } else {
            // the swap transfer transaction[sender is swap address] and [swapAddr -> user address]
            require(_bonusAddr != address(0), "SOCO: the bonus is zero address");
            require(_affiliateAddr != address(0), "SOCO: the affiliate is zero address");

            uint256 bonusAmount     = SafeMath.div(SafeMath.mul(amount, bonusRate), 100);
            uint256 affiliateAmount = SafeMath.div(SafeMath.mul(amount, affiliateRate), 100);
            uint256 realAmount      = SafeMath.sub(SafeMath.sub(amount, bonusAmount), affiliateAmount);

            _transfer(sender, recipient, realAmount);
            _transfer(sender, _bonusAddr, bonusAmount);
            _transfer(sender, _affiliateAddr, affiliateAmount);

            // handle the affiliate & bonus balances
            if (!isContract(recipient)) {
                _bonusLike.append(recipient, bonusAmount);
                _affiliateLike.append(recipient, affiliateAmount);
            }
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "SOCO: transfer from the zero address");
        require(recipient != address(0), "SOCO: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "SOCO: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "SOCO: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "SOCO: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "SOCO: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "SOCO: approve from the zero address");
        require(spender != address(0), "SOCO: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _getSwapAddress() private view returns (address) {
        return  _pancakeFactoryLike.getPair(WBNBAddress, address(this));
    }
}