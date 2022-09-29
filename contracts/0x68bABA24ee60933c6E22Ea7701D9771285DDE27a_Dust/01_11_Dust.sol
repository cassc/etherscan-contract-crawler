// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Dust is AccessControl, ERC20 {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    // Token details
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
   
    mapping (address => bool) public allowedTransfer;
    bool public transferRestricted;
    mapping (address => bool) allowedContracts; 	
     
    // Set total supply here
    uint256 private _tTotal;

    // Tracker for total burned amount
    uint256 private _bTotal;

    // Set the name, symbol, and decimals here
    string constant _name = "DUST";
    string constant _symbol = "DUST";
    uint8 constant _decimals = 18;

    address public WETH;
    address public constant _burnAddress = 0x000000000000000000000000000000000000dEaD;

    // @dev: disallows contracts from entering
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // Edit the constructor in order to declare default fees on deployment
    constructor () ERC20("","") {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(FEE_SETTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        allowedTransfer[_msgSender()] = true;
        allowedTransfer[address(this)] = true;
        allowedTransfer[_burnAddress] = true;   
        transferRestricted = true;
    }

    // @dev: returns the size of the code of an address. If >0, address is a contract. 
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function totalBurned() public view returns (uint256) {
        return _balances[_burnAddress].add(_bTotal);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(msg.sender == tx.origin || allowedContracts[msg.sender], "Proxy contract not allowed");
        if(transferRestricted) { 
            require(allowedTransfer[msg.sender] || allowedTransfer[recipient], "Transfer not allowed"); 
        }
        if (_isContract(msg.sender)) {
            require(allowedContracts[msg.sender], "This contract is not approved to interact with DUST");
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(msg.sender == tx.origin || allowedContracts[msg.sender], "Proxy contract not allowed");
        if(transferRestricted) { 
            require(allowedTransfer[sender] || allowedTransfer[recipient], "Transfer not allowed"); 
        }
        if (_isContract(msg.sender)) {
            require(allowedContracts[msg.sender], "This contract is not approved to interact with DUST");
        }
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function setTransferRestricted(bool _restricted) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DUST: NOT_ALLOWED");
        transferRestricted = _restricted;
    }
    
    function setTransferAllowed(address _account, bool _flag) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DUST: NOT_ALLOWED");
        allowedTransfer[_account] = _flag;
    }

    function addGarageContract(address _gameAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DUST: NOT_ALLOWED");
        grantRole(MINTER_ROLE, _gameAddress);
        grantRole(BURNER_ROLE, _gameAddress);
        allowedContracts[_gameAddress] = true;
        allowedTransfer[_gameAddress] = true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
               
        _balances[from] = _balances[from].sub(amount, "Insufficient Balance");
        _balances[to] = _balances[to].add(amount);

        emit Transfer(from, to, amount);
    }


    function getCirculatingSupply() public view returns (uint256) {
        return _tTotal.sub(balanceOf(_burnAddress)).sub(balanceOf(address(0)));
    }

    // Rescue bnb that is sent here by mistake
    function rescueBNB(uint256 amount, address to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DUST: NOT_ALLOWED");
        payable(to).transfer(amount);
    }

    // Rescue tokens that are sent here by mistake
    function rescueToken(IERC20 token, uint256 amount, address to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DUST: NOT_ALLOWED");
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

    /**	
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.	
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
    ) internal override virtual {	
        uint256 currentAllowance = allowance(owner, spender);	
        if (currentAllowance != type(uint256).max) {	
            require(currentAllowance >= amount, "ERC20: insufficient allowance");	
            unchecked {	
                _approve(owner, spender, currentAllowance - amount);	
            }	
        }	
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) override internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _tTotal = _tTotal.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) override internal {	
        require(account != address(0), 'BEP20: burn from the zero address');	
        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');	
        _tTotal = _tTotal.sub(amount);
        _bTotal = _bTotal.add(amount);	
        emit Transfer(account, address(0), amount);	
    }

    
    function burnFrom(address _from, uint256 _amount) public {	
        require(hasRole(BURNER_ROLE, msg.sender), "DUST: NOT_ALLOWED");	
        _spendAllowance(_from, msg.sender, _amount);
        _burn(_from, _amount);	
        
    }	

    function mint(address _to, uint256 _amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "DUST: NOT_ALLOWED");
        _mint(_to, _amount);
        
    }

    function burn(uint256 _amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "DUST: NOT_ALLOWED");
        _burn(msg.sender, _amount);

    }
	
    function setAllowedContract(address _contract, bool flag) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DUST: NOT_ALLOWED");
        require(_isContract(_contract), "extcodesize != 0: ensure this is a contract, not a wallet!");
        allowedContracts[_contract] = flag;
    }
}