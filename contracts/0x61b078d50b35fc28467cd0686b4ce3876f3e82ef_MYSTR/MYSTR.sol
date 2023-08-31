/**
 *Submitted for verification at Etherscan.io on 2023-08-13
*/

/**

  __  __           _            _                    ____   ____ _______ 
 |  \/  |         | |          (_)                  |  _ \ / __ \__   __|
 | \  / |_   _ ___| |_ ___ _ __ _  ___  _   _ ___   | |_) | |  | | | |   
 | |\/| | | | / __| __/ _ \ '__| |/ _ \| | | / __|  |  _ <| |  | | | |   
 | |  | | |_| \__ \ ||  __/ |  | | (_) | |_| \__ \  | |_) | |__| | | |   
 |_|  |_|\__, |___/\__\___|_|  |_|\___/ \__,_|___/  |____/ \____/  |_|   
          __/ |                                                          
         |___/                                                           
------------------------------

Telegram:
   
      https://t.me/mysteriousbotportal 
     
------------------------------


                                                            
                         .~?Y5PPPPP5Y7:                     
                       !BBY~.      .:!5B5.                  
                    .5#Y:               !&P                 
                   P#7        .::.        B#                
                   B&     :5&@@@@@@B:      @J               
                    J&^ ^BB7!!!!!!!B&      #G               
               :YPGGB@@#@@&&&&&&&&#@#     :@7               
              .@@@@@@@@@@@@@@@@@@@@&.    ^@@#               
            . .@@@@@@@@@@@@@@@@@@&7    :G@@@& ..            
          5@@: &@@@@@BP&@@@@@@B?.   :?B@@@@@5 #@#:          
         ~@@@? P@@@@P   &@#7:   .7PG5~^@@@@@~ @@@B          
          5@@B 7@@@@&^.!@@5    J@@@G..Y@@@@@.^@@#:          
            :: :@@@@@@@@@@&    .@@@@@@@@@@@& .^.            
                @@@@@@@@@@@J5B&@@@@@@@@@@@@B                
                ^#&@@@@@@@@@@&#5B@@@@@@@&&G.                
                     ....7@~    ^@~...                      
                         Y@      @7                         
                         P#555YYJ@B                         
                             ...:::                         
                                                                 
------------------------------

*/


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract MYSTR is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 500_000_000 * 10 ** _decimals;
    string private constant _name = "Mysterious BOT";
    string private constant _symbol = "MYSTR";
    address private _deployer;

    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        _deployer = msg.sender;
    }

    receive() external payable {}

    fallback() external payable {}

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

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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