// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "./Action.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

/*


   _____   _______   _____ _____ ___     ___   _   ___ ___  ___  _  _   ___ _  _ ___ ___  _____   __
  / __\ \ / / _ \ \ / / _ \_   _/ _ \   / __| /_\ | _ \ _ )/ _ \| \| | | __| \| | __| _ \/ __\ \ / /
 | (__ \ V /|   /\ V /|  _/ | || (_) | | (__ / _ \|   / _ \ (_) | .` | | _|| .` | _||   / (_ |\ V /
  \___| |_| |_|_\ |_| |_|   |_| \___/   \___/_/ \_\_|_\___/\___/|_|\_| |___|_|\_|___|_|_\\___| |_|


*/

// Contract to define a ERC20 Token with added functionality of mint and burn
contract CryptoCarbonEnergy is IERC20, SafeMath, Action {
    uint256 private _totalSupply; // Total supply of tokens
    string private _name; // Name of the token
    string private _symbol; // Symbol of the token

    // Mapping to keep track of token balances of each address
    mapping(address => uint) private _balances;

    // Mapping to keep track of allowed transfer of tokens for each address
    mapping(address => mapping(address => uint256)) private _allowances;

    // Constructor to set the name and symbol of the token
    constructor() {
        _name = "Crypto Carbon Energy";
        _symbol = "CYCE";
    }

    // Function to get the total supply of tokens
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // Function to get the balance of tokens for a specific address
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    // Function to get the allowed transfer of tokens for a specific address
    function allowance(
        address tokenOwner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    // Function to get the name of the token
    function name() public view returns (string memory) {
        return _name;
    }

    // Function to get the symbol of the token
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Function to get the decimal places of the token
    function decimals() public pure returns (uint8) {
        return 6;
    }

    // Function to approve a specific address to transfer a specified amount of tokens
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        // Require that the spender address is not zero address
        require(spender != address(0), "ERC20: approve to the zero address");
        // Require that the amount is greater than zero
        require(amount > 0, "invalid value");
        // Update the allowed transfer of tokens
        _allowances[msg.sender][spender] = amount;
        // Emit an approval event
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Function to transfer a specified amount of tokens from the sender to a recipient
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // Call the private transfer function
        _transfer(msg.sender, to, amount);
        return true;
    }

    // Function to transfer a specified amount of tokens from one address to another

    // Transfer tokens from one address to another
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // Ensure that the amount of tokens being transferred does not exceed the approved amount for the transferor
        require(
            amount <= _allowances[from][msg.sender],
            "ERC20: approve to the zero address"
        );
        // Call the private function to handle the transfer
        _transfer(from, to, amount);
        // Decrement the approved amount
        _allowances[from][msg.sender] -= amount;
        return true;
    }

    // Private function to handle the transfer of tokens
    function _transfer(address from, address to, uint256 amount) private {
        // Ensure that the transferor address is not the zero address
        require(from != address(0), "ERC20: transfer from the zero address");
        // Ensure that the recipient address is not the zero address
        require(to != address(0), "ERC20: transfer to the zero address");
        // Ensure that the transferor has enough tokens to transfer
        require(
            _balances[from] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        // Function call for any additional logic to be executed before the transfer
        _beforeTransferToken(from, to, amount);
        // Decrement the transferor's balance
        _balances[from] = safeSub(_balances[from], amount);
        // Increment the recipient's balance
        _balances[to] = safeAdd(_balances[to], amount);
        emit Transfer(from, to, amount);
    }

    // Function to mint new tokens and increase the total supply
    /**
     * @dev mint : To increase total supply of tokens
     */
    function mint(address to, uint256 tokens) public onlyOwner returns (bool) {
        // Increase the total supply
        _totalSupply = safeAdd(_totalSupply, tokens);
        // Increase the balance of the contract owner
        _balances[to] = safeAdd(_balances[to], tokens);
        emit Transfer(address(0), to, tokens);
        return true;
    }

    // Function to burn tokens and decrease the total supply
    /**
     * @dev burn : To decrease total supply of tokens
     */
    function burn(uint tokens) public onlyOwner returns (bool) {
        // Ensure that the contract owner has enough tokens to burn
        require(
            _balances[msg.sender] >= tokens,
            "ERC20: burn amount exceeds balance"
        );
        // Decrease the total supply
        _totalSupply = safeSub(_totalSupply, tokens);
        // Decrease the balance of the contract owner
        _balances[msg.sender] = safeSub(_balances[msg.sender], tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
}
