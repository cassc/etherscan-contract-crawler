/**
 *Submitted for verification at Etherscan.io on 2023-09-18
*/

/*

https://autisticinvestor.lol/

https://t.me/AutisticInvestor



                                  .::::^^^^^^:..                                                    
                             .:~!!~^^^^^^^^^^~~!!!~^.                                               
                         :^!!!~:.   ..  .        .:^!7~                                             
                        77:.      ^7?!^^:.           .?Y.                                           
                      ^?~         !!^.                 ~J                                           
                      5:         .7^  ........:..       J^                                          
                     J~         .^: .:::::::^::^^^::::::~5^                                         
                    !?         ^!.....::^^^::::^^^::::::::J7.                                       
                    Y^           .::::..          . .....  5!                                       
        :?JJ?^     ~?               :^                     ~G~                                      
        5GPPYYY7:  !!            ^       .:::::::      .^^^:?B:                                     
        5PGGJJJYYJ?P~            ~^.     ...    .:.    .:    J!                                     
        5PB5JJJJJJJP!            :~~^^:          ::    :~    ?~                                     
        JGGPJJJJJJJ5Y             ^~~~^                     ~J                                      
        ^BPB5JJJJJJJG7              ..:. ........      .:::.~?                                      
         YGPB5JJJJJJJP^                 .^. ~!7#BJ~. .YPP777:?                                      
         ^GGPGPP55YYJYP^               .  . ~~!YY5Y! .J5!:::^J                                      
          .7J55PGGGGGPGB7      ~~           .   .^^..  !?   ^J                  .^~~7??^            
               .:::G@&P?57      !7.                ..   ?!  ~7                 :J^!~77?~^^^~~:      
  .7YJ???7!!~:.... 7@@#: ~?. ~   ^:              .7::.  .J^ ?:           :~~:  :J.Y:. ^?^?!YJY.     
 ^P#PJJJJYYYYYYYYYJYB#@?  !7 :~:                  ^~~!~^.:Y7^            ~J:?~ ^J Y  77:J^....      
 PGBJJJJJJJJJJJJJJJJJJY5J!?7  ^7::?            !?^::::^7!^J~              :J.7!??.Y:?~:J^           
:GPBJJJJJJJJJJJJJJJJJJJJJYG~.^~~^ 77      !:. .:^:!?7?~!~.Y                ^?::G7 7! 7Y7!^          
^BPBJJJJJJJJYYYYYYYYYYYJJJP! !!~.  ?~     ^!~!^ .  .:.:~~7:                 :Y 77   .5:5^?~         
^BPBJJJJJJJ5?~:::::::^!?JYG?.:     :J     :7!::.     :J~.                    Y. 77.:~Y Y ~?         
^BPBYJJJJ5Y^            .^??~~      Y       ~!775Y55J7:                      J.  ^J~!Y 5J5P         
 YGBYJJJ5!                          ?~       ::.P55YYYJ?!                    Y:   !!~5 !5?~J        
 ?GBYJJJ5               ::..        :~       .~:.:!JJ7?YP?~!!~~~::..~!!~^    ^7^     ^?!G: ?~       
 ^BB5JJJ5               .!Y?         ..              ^~!~!!!!^.:^~!~~~^!??^    ^~~^.  :!! ^YY~.     
 .GGGJJJP!.               ^Y         ::^~..^^:. .^:.:^:.:.               .J!     :!77!~.   ..^?^    
  ?GB5JJ5Y^^:.             Y.           .:~~^^~~~^^^^^^^^!!.               JY7!^:   .^7!.     .~!~: 
  ^GPBJJJP!^~~^^.          ^J.         ~J5Y^^:~~~^ :7.    ^J.               ::~77?7^   :!!^      :~!
  :GPBYJJYB!^~~~~~^^        :J.        .~Y?~7J?!~~^?5      J^    ..    .::.    .^~!7?!:  .^!~:      
  :BPBJJJ5JY~~^:^^^.         77        7!.:!?PBJJ~7J.      ?^   .Y7^::^~~~.      .^^~!!!~:. .!7^    
  :BPBJJ5? !Y^^              .J^       7?!~~~P?5BGY.       ?^   J5777?J7!~^:       .:.  :^~!~::!!.  
  :BPBJJP~  ??~^.             .J:       :J7?!!!7?5.        ?^   ?~ .:::^!7?7~^.             :~!!~7~ 

*/

// SPDX-License-Identifier: Unlicenced

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
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
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
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
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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
contract AutisticInvestor is ERC20 {

    // mint initial supply
    constructor() ERC20("Autistic Investor", "AI$") {
        _mint(msg.sender, 100000000000000000 ether);
    }

    // anyone can burn tokens from their wallet
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}