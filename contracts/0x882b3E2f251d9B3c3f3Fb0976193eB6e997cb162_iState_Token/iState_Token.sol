/**
 *Submitted for verification at Etherscan.io on 2023-05-12
*/

// SPDX-License-Identifier: MIT
// State Token : TOKENIZED REAL ESTATE COMPANY

pragma solidity ^0.8.7;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    function increaseAllowance(address spender, uint256 addedValue) external  returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external  view  returns(string memory);
    function symbol() external view   returns (string memory);
    function decimals() external view  returns (uint8);
    
    function burn(address _from, uint256 _amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public MAX_SUPPLY = 5_648_984_781 * (10 ** uint256(18));
    
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;

    address payable public owner;
        
    mapping (address => bool) public contractAdmin; 

    mapping (address => bool) public allowedWallet;

    address deadAddress = 0x000000000000000000000000000000000000dEaD;   
    
    bool public mintingIsOpen = true;//false

    bool public tradeIsOpen = false;
    
    mapping (address => bool) public identityStored;

    address public stakingContract;
    
    mapping (address => uint256) public vestedAmount;

    mapping (address => bool) public frozenWallet;

    address adminWallet = 0x6D5959772c8ea4F27f1AB57dB96E7C998971E1C5;

    constructor ( string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        owner = payable(msg.sender);
        contractAdmin[msg.sender] = true;
        allowedWallet[msg.sender] = true;
        identityStored[msg.sender] = true;
        identityStored[address(this)] = true;
        allowedWallet[adminWallet] = true;
        identityStored[adminWallet] = true;
    }
    /* The function can be called only from the owner to let permissions to an admin address */
    function addContractAdmin(address _adminUser, bool isAllowed) public {
        require(contractAdmin[msg.sender], "Only Admin can act here");
        contractAdmin[_adminUser] = isAllowed;
        allowedWallet[_adminUser] = isAllowed;
    }

    /* The function allow Wallet to Mint */
    function addAllowedWallet(address _wallet, bool isAllowed) public   {
        require(contractAdmin[msg.sender], "Only Admin can act here");
        allowedWallet[_wallet] = isAllowed;
    }

    // mint pause
    function setMintingStatus( bool isOpen) public returns (bool )  {
        require(contractAdmin[msg.sender], "Only Admin can act here");
        mintingIsOpen = isOpen;
        return isOpen;
    }

    /* After openTrade: holders can buy-sell tokens in an exchange */
    function openTrade(bool _isOpen) public   {
        require(contractAdmin[msg.sender],"Only Admin can open Trade");
        tradeIsOpen = _isOpen;
    }

    /*  Minting function */
    function swapVoucherToToken(address _holder, uint _tokens) payable public  returns (bool ) {//
        require(mintingIsOpen, "Minting is closed");
        require(totalSupply().add(_tokens) <= MAX_SUPPLY,"HARD CAP reached");

        require(allowedWallet[msg.sender], "Only vouchers amount can be minted");
        
        identityStored[_holder] = true;

        _mint(_holder,_tokens);

        return true;
    }
            
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
              
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(((currentAllowance >= amount)), "Transfer amount exceeds allowance ");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance.sub(amount));
             }
        return true;
    }

  
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance.sub(amount);
        }
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply =_totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance.sub(amount);
        }
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

   
    function _approve(address Owner, address spender, uint256 amount) internal virtual {
        require(Owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[Owner][spender] = amount;
        emit Approval(Owner, spender, amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        //allow transfer only between registered holders
        if(!allowedWallet[msg.sender]){
            /* use openTrade to permit transfership to everyone */
            if(!tradeIsOpen){        
                require(identityStored[from] && identityStored[to] , "Transfership is only for registered holders");
            }
        }

        if(vestedAmount[from]>0){
            require(!checkVestedWallet(from,amount),"Vested wallets can't enjoy staking contract for the vested amount");
        }

        require(!frozenWallet[from] && !frozenWallet[to],"Wallet blacklisted. Contact Admin please");

     }
   
	function burn(address _from, uint256 _amount) override external {
		require(contractAdmin[msg.sender],"Only Admin can burn");
		_burn(_from, _amount);
	}

    // withdraw ETH in case of ETH receiving
    function withdrawAdmin() public{
        require(contractAdmin[msg.sender], "Only Admin can act here");
        owner.transfer(address(this).balance);
    }

    //in case of theft or loss, admin can start the recovery procedure
    function recoverWallet(address _old, address _new) public  {
        require(contractAdmin[msg.sender], "Only Admin can act here");
        uint256 balance = balanceOf(_old);
		_balances[_old] = 0;
        _balances[_new] = _balances[_new].add(balance);
        emit Transfer(_old, _new, balance);
	}
    
    function setMaxSupply(uint256 _newMaxWei) public {
        require(contractAdmin[msg.sender], "Only Admin can act here");
        require(_newMaxWei > MAX_SUPPLY, "");

        MAX_SUPPLY = _newMaxWei;
    }

    // Admit KYC wallets  
    function includeToIdentityStored(address[] memory _wallets , bool _isOn) public {
        require(contractAdmin[msg.sender],"Only Admin can act here");
        for(uint8 i = 0; i < _wallets.length; i++) {
            identityStored[_wallets[i]] = _isOn;
        }
    }

    function setStakingContract(address _contract) public {
        require(contractAdmin[msg.sender],"Only Admin can act here");
        stakingContract = _contract;
        identityStored[_contract] = true;
    }

    function includeToVestedWallets(address _wallet ,uint256 _amount) public {
        require(contractAdmin[msg.sender],"Only Admin can act here");
        vestedAmount[_wallet] = _amount;
    }

    function checkVestedWallet(address _wallet , uint256 _amount) public view returns (bool){
        return balanceOf(_wallet).sub(vestedAmount[_wallet]) < _amount;
    }
    
    function getVestedAmount(address _wallet ) public view returns (uint256){
        return vestedAmount[_wallet];
    }

    function freezeWallet(address _wallet,bool _isFrozen) public {
        require(contractAdmin[msg.sender],"Only Admin can act here");
        frozenWallet[_wallet] = _isFrozen;
    }
    
    function checkFrozenWallet(address _wallet) public view returns (bool){
        return frozenWallet[_wallet];
    }

}
contract iState_Token is ERC20 {
    
    constructor() ERC20("State Token", "State",18)  {

    }
}